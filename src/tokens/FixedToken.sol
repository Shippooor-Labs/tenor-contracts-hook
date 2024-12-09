// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.25;

import "./FixedBase.sol";
import { BalanceLib } from "@types/Balance.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title FixedToken
/// @author Tenor Labs
/// @custom:contact security@tenor.finance
/// @notice ERC4626 compliant fixed token contract.
contract FixedToken is FixedBase {
    using Strings for uint256;
    using BalanceLib for uint256;
    using InterestRateLib for InterestRate;
    using ExchangeRateLib for ExchangeRate;

    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#deposit-event
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#withdraw-event
    event Withdraw(
        address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    /// @dev A Fixed token contract is always created when listing new pools.
    /// @param maturity_ Maturity of the Tenor pool this token belongs to.
    constructor(uint40 maturity_) FixedBase(maturity_) { }

    function name() public view returns (string memory) {
        return string(
            abi.encodePacked("Fixed ", MARKET.LOAN_TOKEN().name(), " ", super.maturity().toString())
        );
    }

    function symbol() public view returns (string memory) {
        return
            string(abi.encodePacked("fixed", MARKET.LOAN_TOKEN().symbol(), super.maturity().toString()));
    }

    function balanceOf(address account) public view override returns (uint256) {
        int256 netBalance = MARKET.getFixedRateTokenBalance(account, _maturity);
        return netBalance > 0 ? uint256(netBalance) : 0;
    }

    function totalSupply() public view override returns (uint256) {
        return MARKET.getFixedTokenTotalSupply(_maturity);
    }

    /// @inheritdoc FixedBase
    function isDebt() external pure override returns (bool) {
        return false;
    }

    /// @inheritdoc FixedBase
    function getCurrentInterestRate() public view override returns (uint256) {
        // Code removed.
    }

    /// @inheritdoc FixedBase
    function getCurrentExchangeRate() public view override returns (ExchangeRate) {
        // Code removed.
    }

    /// @inheritdoc FixedBase
    function latestAnswer() public view override returns (int256) {
        // Code removed.
    }

    /// @notice Maximum amount of underlying assets that can be deposited.
    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#maxdeposit
    function maxDeposit(address /* receiver */ ) external view returns (uint256 maxAssets) {
        // Code removed.
    }

    /// @notice Allows to simulate the effects of depositing.
    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#previewdeposit
    function previewDeposit(uint256 assets) external view returns (uint256 shares) {
        // Code removed.
    }

    /// @notice Deposits underlying assets, effectively lending at the current spot rate.
    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#deposit
    function deposit(uint256 assets, address /* receiver */ ) external notMatured returns (uint256 shares) {
        // Code removed.
    }

    /// @notice Maximum amount of loan shares that can be minted.
    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#maxmint
    function maxMint(address /* receiver */ ) external view returns (uint256 maxShares) {
        // Code removed.
    }

    /// @notice Allows to simulate the effects of minting.
    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#previewmint
    function previewMint(uint256 shares) external view returns (uint256 assets) {
        // Code removed.
    }

    /// @notice Mints loan shares, effectively lending at the current spot rate.
    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#mint
    function mint(uint256 shares, address /* receiver */ ) external notMatured returns (uint256 assets) {
        // Code removed.
    }

    /// @notice Maximum amount of underlying assets that can be withdrawn.
    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#maxwithdraw
    function maxWithdraw(address owner) external view returns (uint256 maxAssets) {
        // Code removed.
    }

    /// @notice Allows to simulate the effects of withdrawing.
    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#previewwithdraw
    function previewWithdraw(uint256 assets) external view returns (uint256 shares) {
        // Code removed.
    }

    /// @notice Withdraw underlying assets, effectively repaying a loan.
    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#withdraw
    function withdraw(uint256 assets, address, /* receiver */ address /* owner */ ) external returns (uint256 shares) {
        // Code removed.
    }

    /// @notice Maximum amount of loan shares that can be redeemed.
    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#maxredeem
    function maxRedeem(address owner) external view returns (uint256 maxShares) {
        // Code removed.
    }

    /// @notice Allows to simulate the effects of redeeming.
    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#previewredeem
    function previewRedeem(uint256 shares) external view returns (uint256 assets) {
        // Code removed.
    }

    /// @notice Redeem loan shares, effectively repaying a loan or borrowing at the current spot rate.
    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#redeem
    function redeem(uint256 shares, address, /* receiver */ address /* owner */ ) external returns (uint256 assets) {
        // Code removed.
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        return MARKET.transferFixedFrom(from, to, amount, _maturity);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return MARKET.transferFixed(to, amount, _maturity);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return MARKET.approveFixed(spender, amount, _maturity);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return MARKET.allowanceFixed(owner, spender, _maturity);
    }
}
