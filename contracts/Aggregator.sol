// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./library/QuickSort.sol";
import "./utils/ERC20Utils.sol";
import "./IValidator.sol";

contract Aggregator is ERC20Utils {
    // Temperature are stored in fixed-point format, with this many digits of precision
    uint8 public constant decimals = 2;

    // Lowest temperature -100°C the system is allowed to report in response to aggregate result
    int16 public constant minTemperature = -10000;

    // Highest temperature 100°C the system is allowed to report in response to aggregate result
    int16 public constant maxTemperature = 10000;

    // Aggregate transmit array item threshold
    uint8 public constant threshold = 10;

    // Aggregate transmit array item time range
    uint16 public constant timeRange = 600;

    // latest aggregate round id
    uint32 public latestAggregatorRoundId;

    // Validator address
    address public validator;

    // 20°C
    uint16 public constant differenceThreshold = 2000;

    //ERC20 address
    address public immutable KONO;

    // Temperature data feeds from transmitter
    struct Transmit {
        address transmitter;
        int16 temperature;
        uint64 timestamp;
    }

    // temporary storage a round transmits
    Transmit[] internal transmits;

    using QuickSort for int16[];

    // Records the median temperature from the transmit array
    struct AggregateResult {
        int16 temperature;
        uint64 timestamp;
    }

    // Round ID to aggregate result
    mapping(uint32 => AggregateResult) public aggregateResults;

    mapping(address => address) public consumerToSubscriber;

    constructor(address _validator, address _kono) {
        validator = _validator;
        KONO = _kono;
    }

    // eoa transmitter call this method submit data
    function submit(int16 _temperature) external returns (bool) {
        // check access
        require(IValidator(validator).hasAccess(msg.sender, msg.data), "No access.");
        if (_temperature < minTemperature || _temperature > maxTemperature) {
            IValidator(validator).validate(latestAggregatorRoundId + 1, msg.sender, _temperature);
            return true;
        }

        // temporary storage
        Transmit memory transmit = Transmit(msg.sender, _temperature, uint64(block.timestamp));
        for (uint256 i = 0; i < transmits.length; i++) {
            // do not need one transmitter push single temperature twice in one timeRange
            if (transmits[i].transmitter == msg.sender && transmits[i].timestamp > (block.timestamp - timeRange)) {
                return true;
            }
            transmits.push(transmit);
        }

        return _aggregate();
    }

    function _aggregate() private returns (bool) {
        // no need
        if (transmits.length < threshold) {
            return true;
        }

        // only need newest {{threshold}} transmits
        uint256 startIndex = transmits.length - threshold;
        // need all transmits timestamp > (current - timeRange)
        if (transmits[startIndex].timestamp < (block.timestamp - timeRange)) {
            return true;
        }

        int16[] memory temperatures = new int16[](uint256(threshold));
        for (uint256 i = startIndex; i < transmits.length; i++) {
            temperatures[i] = transmits[i].temperature;
        }

        // sort temperatures
        // should sort data feed off chain in reality
        temperatures = temperatures.sort();

        // get median as aggregate result
        int16 median = temperatures[uint256(temperatures.length / 2)];
        AggregateResult memory aggregateResult = AggregateResult(median, uint64(block.timestamp));

        latestAggregatorRoundId++;
        aggregateResults[latestAggregatorRoundId] = aggregateResult;

        for (uint256 i = 0; i < transmits.length; i++) {
            int16 difference = transmits[i].temperature - median;
            difference = difference >= 0 ? difference : -difference;
            if (uint16(difference) > differenceThreshold) {
                IValidator(validator).validate(
                    latestAggregatorRoundId,
                    transmits[i].transmitter,
                    transmits[i].temperature
                );
            } else {
                IValidator(validator).reward(transmits[i].transmitter);
            }
            // give transmits[length-1] more reward
        }

        //clear transmits storage
        delete transmits;

        //emit event

        return true;
    }

    // eoa call this method subscribe for consumer contract
    function subscribe(address _consumer) external {
        require(consumerToSubscriber[_consumer] == address(0), "Already subscribe.");
        require(IERC20(KONO).allowance(msg.sender, address(this)) > 0, "Insufficient allowance.");
        consumerToSubscriber[_consumer] = msg.sender;
    }

    // consumer contract will call this method
    function latestTemperature() public returns (int256 temperature, uint64 timestamp) {
        address subscriber = consumerToSubscriber[msg.sender];
        require(subscriber != address(0), "Invalid subscribe.");
        // charge subscriber fees，1e18 is an example
        _safeTransferFrom(KONO, subscriber, validator, 1e18);
        AggregateResult memory latestAggregateResult = aggregateResults[latestAggregatorRoundId];
        temperature = latestAggregateResult.temperature;
        timestamp = latestAggregateResult.timestamp;
    }
}
