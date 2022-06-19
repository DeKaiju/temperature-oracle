// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IValidator {
    function hasAccess(address transmitter, bytes calldata data) external view returns (bool);

    function reward(address _transmitter) external;

    function validate(
        uint32 roundId,
        address transmitter,
        int16 temperature
    ) external;
}
