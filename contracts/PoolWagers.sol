pragma solidity ^0.5.0;
//import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./AuthorityGranter.sol";
contract PoolWagers is AuthorityGranter {
         
    struct Wager {
        bytes32 eventId;        
        uint origValue;             
        uint makerChoice;       
        address maker;        
        bool settled;        
    }
 
    mapping (bytes32 => Wager) wagersMap;
    mapping (address => mapping (bytes32 => bool)) recdRefund;  
    
    function makeWager (
        bytes32 wagerId, 
        bytes32 eventId,        
        uint origValue,       
        uint makerChoice,     
        address maker
        )
            external
            onlyAuth             
        {
        Wager memory thisWager = Wager (eventId,
                                        origValue,                                       
                                        makerChoice,                                      
                                        maker,                                         
                                        false);
        wagersMap[wagerId] = thisWager;       
    }    

   
    function setSettled (bytes32 wagerId) external onlyAuth { wagersMap[wagerId].settled = true; }   

    function setRefund (address bettor, bytes32 wagerId) external onlyAuth { recdRefund[bettor][wagerId] = true; }  
  
    function getEventId(bytes32 wagerId) external view returns (bytes32) { return wagersMap[wagerId].eventId; }

    function getSettled (bytes32 id) external view returns (bool) { return wagersMap[id].settled; }

    function getMaker(bytes32 id) external view returns (address) { return wagersMap[id].maker; }  

    function getMakerChoice (bytes32 id) external view returns (uint) { return wagersMap[id].makerChoice; }    

    function getRefund (address bettor, bytes32 wagerId) external view returns (bool) { return recdRefund[bettor][wagerId]; }
   
    function getOrigValue (bytes32 id) external view returns (uint) { return wagersMap[id].origValue; }
 

}
        
