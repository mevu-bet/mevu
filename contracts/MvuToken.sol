pragma solidity ^0.4.18;


//import './MvuTokenBet.sol';
import '../zeppelin-solidity/contracts/token/MintableToken.sol';

/**
 * @title MvuToken
 * @dev Mintable ERC20 Token which also controls a one-time bet contract, token transfers locked until sale ends.
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MvuToken is MintableToken {
    event TokensMade(address indexed to, uint amount); 
    uint  saleEnd = 1515645598; // TODO: Update with actual date
    uint betsEnd = 1519000651;  // TODO: Update with actual date
    uint tokenCap = 100000000; // TODO: Update with actual cap
    //MvuTokenBet public bet;
 
    modifier saleOver () {
        require (now > saleEnd);
        _;
    }

    modifier betsAllowed () {
        require (now < betsEnd);
        _;
    }

    modifier underCap (uint tokens) {
        require(totalSupply + tokens < tokenCap);
        _;
    }

    function MvuToken (uint initFounderSupply) {   
        balances[msg.sender] = initFounderSupply;
        TokensMade(msg.sender, initFounderSupply);      
        totalSupply += initFounderSupply;
        //bet = createBetContract();   
    }
    
    // function createBetContract () internal returns (MvuTokenBet) {
    //   return new MvuTokenBet();
    // }

    function transfer (address _to, uint _value) saleOver public returns (bool) {
        super.transfer(_to, _value);
    }

    function mint(address _to, uint _amount) onlyOwner canMint underCap(_amount) public returns (bool) {
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