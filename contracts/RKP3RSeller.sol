pragma solidity ^0.8.2;

import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IRKP3R.sol";
import "../interfaces/IUniswap.sol";
import "../interfaces/IUniswapV3.sol";
import "../interfaces/IStableSwap.sol";
import "../interfaces/IibAMM.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RKP3rSeller is Ownable {
	using SafeERC20 for IERC20;

	address public constant KP3R = address(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);
	address public constant RKP3R = address(0xEdB67Ee1B171c4eC66E6c10EC43EDBbA20FaE8e9);
	address public constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
	address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
	address public constant MIM = address(0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3);
	address public constant KEEPERDAO = address(0x4F868C1aa37fCf307ab38D215382e88FCA6275E2);
	address public constant BORROWER = address(0x17a4C8F43cB407dD21f9885c5289E66E21bEcD9D);
	address public constant SUSHI = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
	address public constant CURVE_MIM = address(0x5a6A4D54456819380173272A5E8E9B9904BdF41B);
	address public constant IB_AMM = address(0x8338Aa899fB3168598D871Edc1FE2B4F0Ca6BBEF);

	constructor() public {
		IERC20(USDC).approve(RKP3R, type(uint256).max);
		IERC20(USDC).approve(CURVE_MIM, type(uint256).max);
		IERC20(KP3R).approve(SUSHI, type(uint256).max);
		IERC20(MIM).approve(IB_AMM, type(uint256).max);
	}

	function preApprove(address[] calldata _tokens, address[] calldata _spenders) external onlyOwner {
		for(uint256 i = 0 ; i < _tokens.length; i++)
			IERC20(_tokens[i]).approve(_spenders[i], type(uint256).max);
	}

	function initiateConvertRKP3RToIB(uint256 _amount, address _IBToken, address _factoryPool, address _receiver) external {
		IERC20(RKP3R).safeTransferFrom(msg.sender, address(this), _amount);
		uint256 nftId = IRKP3R(RKP3R).claim(_amount);
		(uint256 kprAmount, uint256 strike,,) = IRKP3R(RKP3R).options(nftId);
		bytes memory data = abi.encodeWithSelector(RKP3rSeller.fallbackSellKP3RToUSDCSushi.selector, kprAmount, nftId, strike);
		ILiquidityPool(KEEPERDAO).borrow(USDC, strike, data);
		// 2 is USDC, 0 is mim
		uint256 out = IStableSwap(CURVE_MIM).exchange_underlying(2, 0, IERC20(USDC).balanceOf(address(this)), 0);
		uint256 ibTokenAmount = IIbAMM(IB_AMM).quote(_IBToken, out);
		IIbAMM(IB_AMM).swap(_IBToken, out, 0);
		// Checked all pools, index 0 is always IB coin
		IStableSwap(_factoryPool).add_liquidity([ibTokenAmount, 0], 0, _receiver);
	}


	function fallbackSellKP3RToUSDCSushi(uint256 _KP3Ramount, uint256 _nftId, uint256 _repayAmount) external {
		require(msg.sender == BORROWER, "!keeperDAO");
		IRKP3R(RKP3R).redeem(_nftId);
		address[] memory path = new address[](3);
		path[0] = KP3R;
		path[1] = WETH;
		path[2] = USDC;
		IUniswap(SUSHI).swapExactTokensForTokens(
			_KP3Ramount,
			0,
			path,
			address(this),
			block.timestamp
		);
		IERC20(USDC).safeTransfer(KEEPERDAO, _repayAmount + 0);
	}

	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
		return RKP3rSeller.onERC721Received.selector;
	}

	function exec(address _target, uint256 _value, bytes calldata _data) external payable onlyOwner {
		(bool success, bytes memory data) = _target.call{value:_value}(_data);
		require(success);
	}
}
