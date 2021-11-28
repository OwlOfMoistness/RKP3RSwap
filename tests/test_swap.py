import pytest
import brownie
from brownie import Wei, accounts

def test_swap(accounts, kpr_swap, minter, interface, usdc):
	ib_eur = '0x96E61422b6A9bA0e068B6c5ADd4fFaBC6a4aae27'
	ib_gbp = '0x69681f8fde45345c3870bcd5eaf4a05a60e7d227'
	ib_chf = '0x1cc481ce2bd2ec7bf67d1be64d4878b16078f309'
	ib_aud = '0xfafdf0c4c1cb09d430bf88c75d88bb46dae09967'
	ib_krw = '0x95dfdc8161832e4ff7816ac4b6367ce201538253'
	ib_jpy = '0x5555f75e3d5278082200fb451d1b6ba946d8e13b'

	pool_ib_eur = interface.IERC20('0x19b080FE1ffA0553469D20Ca36219F17Fcf03859')
	pool_ib_gbp = interface.IERC20('0xD6Ac1CB9019137a896343Da59dDE6d097F710538')
	pool_ib_chf = interface.IERC20('0x9c2C8910F113181783c249d8F6Aa41b51Cde0f0c')
	pool_ib_aud = interface.IERC20('0x3F1B0278A9ee595635B61817630cC19DE792f506')
	pool_ib_krw = interface.IERC20('0x8461A004b50d321CB22B7d034969cE6803911899')
	pool_ib_jpy = interface.IERC20('0x8818a9bb44Fbf33502bE7c15c500d0C783B73067')

	rkpr = interface.IERC20('0xedb67ee1b171c4ec66e6c10ec43edbba20fae8e9')
	rkpr_whale = accounts.at('0xf3537ac805e1ce18aa9f61a4b1dcd04f10a007e9', force=True)

	tokens = [ib_eur,ib_gbp,ib_chf,ib_aud,ib_krw,ib_jpy]
	pools = [pool_ib_eur,pool_ib_gbp,pool_ib_chf,pool_ib_aud,pool_ib_krw,pool_ib_jpy]

	kpr_swap.preApprove(tokens, pools, {'from':minter})

	rkpr.approve(kpr_swap, 2 ** 256 - 1, {'from':rkpr_whale})

	for token, pool in zip(tokens, pools):
		assert pool.balanceOf(accounts[0]) == 0
		kpr_swap.initiateConvertRKP3RToIB('10 ether', token, pool, accounts[0], {'from':rkpr_whale})
		assert usdc.balanceOf(kpr_swap) == 0
		print(f'IB LP : {Wei(pool.balanceOf(accounts[0]).to("ether"))}')
		assert pool.balanceOf(accounts[0]) > 0
