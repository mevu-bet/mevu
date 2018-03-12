pragma solidity ^0.4.18;


//import './MvuTokenBet.sol';
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
        //bet = createBetContract();   
    }
    
    // function createBetContract () internal returns (MvuTokenBet) {
    //   return new MvuTokenBet();
    // }

    function transfer (address _to, uint _value)  public returns (bool) {
        super.transfer(_to, _value);
    }

    function mint(address _to, uint _amount) onlyOwner canMint public returns (bool) {
        super.mint(_to, _amount);
    }

    // function claimWin () external saleOver {
    //   require(bet.checkMade(msg.sender));
    //   require(!bet.checkSettled(msg.sender));
    //   bet.settle(msg.sender);   
    //     if (bet.checkWin(msg.sender)){            
    //         uint winnings = bet.getTokensPurchased(msg.sender)/10;
    //         balances[msg.sender] += winnings;
    //         TokensMade(msg.sender, winnings);           
    //     } 
    // }

    // function makeBet (address bettor, uint winnerChoice, uint numTokensPurchased) onlyOwner betsAllowed {
    //     bet.makeBet(bettor, winnerChoice, numTokensPurchased);
    // }

    // function setEventWinner (uint winner) external onlyOwner {
    //     bet.setEventWinner(winner);
    // }
 

} 