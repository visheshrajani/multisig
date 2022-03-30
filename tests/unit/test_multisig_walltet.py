from brownie import exceptions
import pytest
from scripts.utils import get_account
from scripts.deploy import deploy
import eth_utils
from web3 import Web3

def test_submit():
    account = get_account()
    multi_sig = deploy()

    tx = multi_sig.submit(
            account, 
            Web3.toWei(1, "ether"), 
            eth_utils.to_bytes(hexstr="0x"),
            {"from":account}
        )
    tx.wait(1)
    assert multi_sig.transactions(0)["to"] == account
    assert multi_sig.transactions(0)["value"] == Web3.toWei(1, "ether")

    return multi_sig

def test_approve():
    multi_sig = test_submit()
    account_2 = get_account(1)
    assert multi_sig.approved(0,account_2) == False
    tx = multi_sig.approve(0, {"from":account_2})
    tx.wait(1)
    assert multi_sig.approved(0,account_2) == True
    return multi_sig

def test_execute():
    multi_sig = test_approve()
    account = get_account()

    with pytest.raises(exceptions.VirtualMachineError):
        multi_sig.execute(0, {"from":account})
    tx = multi_sig.approve(0, {"from":account})
    tx.wait(1)
    assert multi_sig.transactions(0)["executed"] == False
    
    tx = multi_sig.execute(0, {"from":account})
    tx.wait(1)

    assert multi_sig.transactions(0)["executed"] == True
    



    


