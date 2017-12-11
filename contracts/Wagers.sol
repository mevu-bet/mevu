pragma solidity ^0.4.18; 

import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Wagers is Ownable {

    struct Wager {
        bytes32 eventId;        
        uint origValue;
        uint winningValue;        
        uint makerChoice;
        uint takerChoice;
        uint odds;
        uint makerWinnerVote;
        uint takerWinnerVote;
        address maker;
        address taker;        
        address winner;
        address loser;
        bool makerCancelRequest;
        bool takerCancelRequest;
        bool locked;
        bool settled;        
    }

    mapping (bytes32 => Wager) wagersMap;

    function makeWager (
        bytes32 id, 
        uint origValue,
        uint winningValue,
        bytes32 eventId,
        address maker,
        uint makerChoice, 
        uint takerChoice,
        uint odds
    ) 
        onlyOwner
    {
        Wager memory thisWager;                
        thisWager = Wager ( eventId,
                            origValue,
                            winningValue,                           
                            makerChoice,
                            takerChoice,
                            odds,
                            0,
                            0,
                            maker,
                            address(0),                          
                            address(0),
                            address(0),
                            false,
                            false,
                            false,
                            false);
        wagersMap[id] = thisWager;
    }

    function takeWager (bytes32 id, address taker, uint takeValue) onlyOwner {
        wagersMap[id].taker = taker;
        wagersMap[id].locked = true; 
        wagersMap[id].winningValue = wagersMap[id].origValue + takeValue;
    }  
    


   
    function setLocked (bytes32 wagerId) external onlyOwner {
        wagersMap[wagerId].locked = true;
    }

    function setSettled (bytes32 wagerId) external onlyOwner {
        wagersMap[wagerId].settled = true;
    }

    function setMakerWinVote (bytes32 id, uint winnerVote) {
        wagersMap[id].makerWinnerVote = winnerVote;
    }

    function setTakerWinVote (bytes32 id, uint winnerVote) external onlyOwner {
        wagersMap[id].takerWinnerVote = winnerVote;
    }

    function setMakerCancelRequest (bytes32 id) external onlyOwner {
        wagersMap[id].makerCancelRequest = true;
    }

    function setTakerCancelRequest (bytes32 id) external onlyOwner {
        wagersMap[id].takerCancelRequest = true;
    }

    function getEventId(bytes32 wagerId) external view returns (bytes32) {
        return wagersMap[wagerId].eventId;
    }

    function getMaker(bytes32 id) external view returns (address) {
        return wagersMap[id].maker;
    }

    function getTaker(bytes32 id) external view returns (address) {
        return wagersMap[id].taker;
    }

    function getMakerChoice (bytes32 id) external view returns (uint) {
        return wagersMap[id].makerChoice;
    }

    function getTakerChoice (bytes32 id) external view returns (uint) {
        return wagersMap[id].takerChoice;
    }

    function getMakerCancelRequest (bytes32 id) external view returns (bool) {
        return wagersMap[id].makerCancelRequest;
    }

    function getTakerCancelRequest (bytes32 id) external view returns (bool) {
        return wagersMap[id].takerCancelRequest;
    }

    function getMakerWinVote (bytes32 id) external view returns (uint) {
        return wagersMap[id].makerWinnerVote;
    }

    function getTakerWinVote (bytes32 id) external view returns (uint) {
        return wagersMap[id].takerWinnerVote;
    }

    function getOdds (bytes32 id) external view returns (uint) {
        return wagersMap[id].odds;
    }

    function getOrigValue (bytes32 id) external view returns (uint) {
        return wagersMap[id].origValue;
    }

    function getWinningValue (bytes32 id) external view returns (uint) {
        return wagersMap[id].winningValue;

    }

}