// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./access/WriteAccessController.sol";
import "./utils/ERC20Utils.sol";

contract Validator is WriteAccessController, ERC20Utils {
    address public immutable KONO;
    // aggregator address
    address public aggregator;

    uint256 public constant stakingAmount = 10000e18;

    mapping(address => uint256) public balances;

    event Validated(uint256 roundId, address transmitter, int256 temperature);

    event Slash(uint256 roundId, address transmitter, int256 temperature, uint256 slashAmount);

    constructor(address _kono) {
        KONO = _kono;
    }

    function setAggregatorAddress(address _aggregator) external onlyOwner {
        aggregator = _aggregator;
    }

    // transmitter join in protocol
    function join() external {
        require(!hasAccess(msg.sender, msg.data), "Already have access.");
        _safeTransferFrom(KONO, msg.sender, address(this), stakingAmount);
        balances[msg.sender] = stakingAmount;
        addAccessInternal(msg.sender);
        // emit event if needed
    }

    // transmitter quit protocol
    // owner approval is generally required in reality
    function quit() external {
        require(hasAccess(msg.sender, msg.data), "No access.");
        removeAccessInternal(msg.sender);
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        _safeTransfer(KONO, msg.sender, balance);
        //emit event if needed
    }

    // aggregator call this method to pay transmitters
    function reward(address _transmitter) public {
        require(msg.sender == aggregator, "Not aggregator.");
        balances[_transmitter] = balances[_transmitter] + 10e18;
    }

    // aggregator call this method to validate outlier
    function validate(
        uint32 _roundId,
        address _transmitter,
        int16 _temperature
    ) public {
        require(msg.sender == aggregator, "Not aggregator.");
        // validator node validate data off chain.
        emit Validated(uint256(_roundId), _transmitter, int256(_temperature));
    }

    // slash transmitter balance called by owner if transmitter submit wrong value
    function slash(
        uint32 _roundId,
        address _transmitter,
        int16 _temperature
    ) external onlyOwner {
        // 1000e18 is just an example slash amount
        uint256 slashAmount = 1000e18;
        balances[_transmitter] = balances[_transmitter] - slashAmount;
        emit Slash(uint256(_roundId), _transmitter, int256(_temperature), slashAmount);
    }
}
