import pytest
import csv

@pytest.fixture(scope="function", autouse=True)
def shared_setup(fn_isolation):
    pass

@pytest.fixture()
def minter(accounts):
    return accounts[0]

@pytest.fixture()
def usdc(interface):
    return interface.IERC20('0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48')

@pytest.fixture()
def kpr_swap(RKP3rSeller, minter, usdc):
    return RKP3rSeller.deploy({'from':minter})
