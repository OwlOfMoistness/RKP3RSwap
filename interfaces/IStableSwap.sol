pragma solidity ^0.6.12;

interface IStableSwap {
	function calc_withdraw_one_coin(uint256, int128) external view returns(uint256);
	function calc_withdraw_one_coin(uint256, int128, bool) external view returns(uint256);
	function remove_liquidity_one_coin(uint256, int128, uint256, bool) external;
	function add_liquidity(uint256[2] calldata,uint256) external;
		function add_liquidity(uint256[2] calldata,uint256,address) external;
}