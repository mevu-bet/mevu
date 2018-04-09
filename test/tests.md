# Test Cases

## Player Cases
---
### Standard Bets
---
1. Case 1 - Players Bet and Agree on Outcome
  * player 1 creates bet
  * player 2 takes bet  
  **[Event transpires]**  
  * player 1 reports event outcome
  * player 2 reports outcome and agrees
  * ETH is paid out and Rep is gained
---
2. Case 2 - Players Bet and Disagree (Not Enough Oracles)
  * player 3 creates bet
  * player 4 takes bet  
  **[Event transpires]**  
  * player 3 reports event outcome
  * player 4 reports outcome and disagrees  
  **[Oracle period ends]**   
  *(not enough Oracles registered)*
  * a player calls the cancel function
  * ETH is refunded
  ---
3. Case 3 - Players Bet and Disagree (With Enough Oracles)
  * player 5 creates bet
  * player 6 takes bet  
**[Event transpires]**  
  * player 5 reports event outcome  
  * player 6 reports outcome and disagrees   
**[Oracle period ends]**  
  *(there are enough Oracles registered)*  
  * winner calls submit vote
  * ETH is paid out, loser loses rep and winner gains rep
  ---
4. Case 4 - Player Bets and it is Never Taken
  * player 7 creates bet
  * bet is never taken
  * player 7 cancels the bet
  ---
5. Case 5 - Players Bet and the Event is Cancelled
  * player 7 creates Bet
  * player 8 takes the Bet  
    **[Event is cancelled]**  
  * both players call playerRefund in Mevu.sol
  ---
6. Case 6 - Players Bet and the Loser Never Reports (Not Enough Oracles)
  * player 9 creates bet
  * player 10 takes bet  
    **[Event Transpires]**   
  * the losing player never reports  
    **[Oracle period ends]**   
  *(not enough Oracles registered)*  
  * winning player calls the submitVote function again and wager is aborted
  * ETH is refunded
  ---
7. Case 7 - Players Bet and the Loser Never Reports (With Enough Oracles)
  * player 9 creates bet
  * player 10 takes bet  
    **[Event transpires]**  
  * the losing player never reports  
    **[Oracle period ends]**   
  *(there are enough Oracles registered)*  
  * winning player calls submitVote
  * ETH is paid out, loser loses rep and winner gains rep
  ---
### Custom Bets
---
1. Case 1 - Player Bets and it is Never Taken
  * player 1 creates bet
  * the bet is never taken
  * player 1 cancels bet
---
2. Case 2 - Players Bet and Agree on Outcome
  * player 1 creates bet
  * player 2 takes bet  
**[Event transpires]**
  * player one reports event outcome
  * player two reports outcome and agrees
  * ETH is paid out and Rep is gained
---
3. Case 3 - Players Bet and Disagree on Outcome (No Judge)
  * player 3 creates bet
  * player 4 takes bet  
    **[Event transpires]**  
  * player 3 reports event outcome
  * player 4 reports event outcome and disagrees  
  *(no judge was assigned and wager is aborted)*  
---
4. Case 4 - Players Bet and Disagree on Outcome (With Judge)
  * player 5 creates bet
  * player 6 takes bet  
    **[Event transpires]**  
  * player 5 reports event outcome
  * player 6 reports event outcome and disagrees
  * a Judge is assigned and Judge submits vote, payout is triggered
  ---
5. Case 5 - Players Bet and Losing Player Never Reports
  * player 7 creates bet
  * player 8 takes bet  
    **[Event transpires]**  
*(losing player never reports and no Judge assigned)*  
  * winner calls finalizeAbandonedBet
---
##  Oracle Cases  
>Note: All Oracles need to be verified in OracleVerifier.sol  
---
1. Case 1 - Oracle Registers with Consensus
  * Oracle registers for event  
    **[Oracle period ends]**  
  *(they are with consensus)*  
  * Oracle calls claimReward
  * Oracle calls withdraw
  ---
2. Case 2 - Oracle Registers against Consensus
  * Oracle registers for event  
    **[Oracle period ends]**  
  *(they are NOT with consensus)*  
  * Oracle calls claimReward, only half of stake is returned and no ETH
  * Oracle calls withdraw to get MVU tokens back
  ---
3. Case 3 - Not Enough Oracles
  * Oracle registers for event  
    **[Oracle period ends]**  
  *(not enough Oracles)*  
  * Oracle calls claim refund
  ---
## Event Cases
---
1. Case 1 - Event is Used Fully
  * Event is made
  * Event is bet upon  
  **[Event Transpires]**  
  * Event is Oraclized  
  **[Oracle Period Ends]**  
  * Event is removed from the active events array
  ---
2. Case 2 - Event is Cancelled
  * Event is made
  * Event is cancelled
  ---
3. Case 2 - Event is Used then Cancelled
  * Event is made
  * Event is bet upon
  * Event is then cancelled
