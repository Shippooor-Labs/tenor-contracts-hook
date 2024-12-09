// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.25;

import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import { Market } from "../Market.sol";

/// @title FixedBase
/// @author Tenor Labs
/// @custom:contact security@tenor.finance
/// @notice Common ERC4626 compliant base contract for Tenor's fixed rate and fixed rate debt tokens.
abstract contract FixedBase is IERC20Metadata {

    /// @notice Tenor market.
    Market public immutable MARKET;

    uint8 internal immutable _decimals;
    uint8 internal immutable _assetDecimals;
    IERC20Metadata internal immutable _asset;
    uint40 internal immutable _maturity;

    /// @dev Reverts if the maturity has been reached.
    modifier notMatured() {
        require(!isMatured());
        _;
    }

    /// @dev Restrict access to the Tenor market.
    modifier onlyMarket() {
        require(msg.sender == address(MARKET));
        _;
    }

    /// @dev While ERC20 is supported, a custom accounting is used instead of transfers.
    /// @param maturity_ Maturity of the Tenor pool this token belongs to.
    constructor(uint40 maturity_) {
        Market market = Market(msg.sender);
        MARKET = market;

        IERC20Metadata asset_ = market.UNDERLYING_TOKEN();
        // Match decimals with underlying
        _assetDecimals = asset_.decimals();
        _decimals = market.LOAN_TOKEN().decimals();
        _maturity = maturity_;
        _asset = asset_;
    }

    function totalSupply() public view virtual override returns (uint256);

    /// @notice The maturity of the Tenor pool this token belongs to.
    function maturity() public view returns (uint40) {
        return _maturity;
    }

    /// @notice Whether the maturity has been reached.
    function isMatured() public view returns (bool) {
        // TODO: implement.
    }

    /// @inheritdoc IERC20Metadata
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /// @notice Underlying asset of the Tenor market.
    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#asset
    function asset() external view returns (address) {
        return address(_asset);
    }

    /// @notice Total amount of underlying assets.
    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#totalassets
    function totalAssets() external view returns (uint256 totalManagedAssets) {
        return convertToAssets(totalSupply());
    }

    /// @notice Amount of shares for a given amount of assets.
    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#convertoshares
    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        // Code removed.
    }

    /// @notice Amount of assets for a given amount of shares.
    /// @dev ERC4626 compliance: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/#convertoassets
    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        // Code removed.
    }

    /// @notice Current exchange rate for collateral checks.
    function getCurrentExchangeRate() public view virtual returns (uint256);

    /// @notice Spot interest rate.
    function getCurrentInterestRate() public view virtual returns (uint256);

    /// @notice Whether the token is a debt token.
    function isDebt() external pure virtual returns (bool);

    /// @notice Current exchange rate for collateral checks.
    function latestAnswer() external view virtual returns (int256);

    /// @notice Amount of underlying assets for a given number of market loan tokens.
    /// @param loanAmount Amount of market loan tokens.
    function convertLoanToAsset(uint256 loanAmount) public view returns (uint256) {
        // Code removed.
    }

    /// @notice Amount of market loan tokens for a given number of underlying assets.
    /// @param assets Amount of underlying tokens.
    function convertAssetToLoan(uint256 assets) public view returns (uint256) {
        // Code removed.
    }

    /// @notice Allows ERC20 transfer events to be emitted from the proper address so that
    /// wallet tools can properly track balances.
    function emitTransfer(address from, address to, uint256 amount) external override onlyMarket {
        emit Transfer(from, to, amount);
    }

    /// @notice Allows ERC20 approval events to be emitted from the proper address so that
    /// wallet tools can properly track balances.
    function emitApproval(address owner, address spender, uint256 value) external override onlyMarket {
        emit Approval(owner, spender, value);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        revert();
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        revert();
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        revert();
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        revert();
    }
}
