// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import "./FixedToken.sol";
import "./FixedDebt.sol";

library FixedTokenFactory {
    function createFixedToken(uint40 maturity)
        external
        returns (address fixedTokenAddress, address fixedDebtTokenAddress)
    {
        // CREATE2 salt is a combination of the market address and the maturity.
        bytes32 fixedTokenSalt = keccak256(abi.encodePacked(address(this), maturity, /* isDebt */ false));
        bytes32 fixedDebtTokenSalt = keccak256(abi.encodePacked(address(this), maturity, /* isDebt */ true));

        FixedToken f = new FixedToken{ salt: fixedTokenSalt }(maturity);
        FixedDebt d = new FixedDebt{ salt: fixedDebtTokenSalt }(maturity);

        return (address(f), address(d));
    }
}
