import imp
from brownie import MultiSigWallet
from .utils import get_account
from web3 import Web3

def main():
    deploy()

def deploy():
    account_1 = get_account()
    account_2 = get_account(1)
    account_3 = get_account(2)

    address = [account_1, account_2, account_3]
    multi_sig = MultiSigWallet.deploy(address, 2, {"from": account_1, "value": Web3.toWei(2,"ether")})

    return multi_sig
