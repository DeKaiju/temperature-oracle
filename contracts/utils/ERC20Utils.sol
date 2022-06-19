// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20Utils {
    // erc20 token transfer
    function _safeTransfer(
        address _erc20Address,
        address _to,
        uint256 _value
    ) internal {
        require(IERC20(_erc20Address).transfer(_to, _value), "Fail to transfer");
    }

    // erc20 token safe transferFrom
    function _safeTransferFrom(
        address _erc20Address,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(IERC20(_erc20Address).transferFrom(_from, _to, _value), "Fail to transferFrom");
    }
}
