pragma solidity ^0.4.18;

import '../zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';

/**
 * @title MvuToken
 * @dev Mintable ERC20 Token which also controls a one-time bet contract, token transfers locked until sale ends.
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */


contract MvuToken is MintableToken {


    event TokensMade(address indexed to, uint amount);   

    function MvuToken (uint initFounderSupply) {   
        balances[msg.sender] = initFounderSupply;
        TokensMade(msg.sender, initFounderSupply);      
        totalSupply_ += initFounderSupply;        
    }     

    function transfer (address _to, uint _value)  public returns (bool) {
        super.transfer(_to, _value);
    }

    function mint(address _to, uint _amount) onlyOwner canMint public returns (bool) {
        super.mint(_to, _amount);
    } 

} 