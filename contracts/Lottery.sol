pragma solidity 0.4.18;
import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract Lottery is usingOraclize, Ownable {
 

   
    /** @dev Calls the oraclize contract for a random number generated through the Wolfram Alpha engine
      * @param max uint which corresponds to entries in oracleList array.
      */ 
    function randomNum(uint256 max) private {
        //randomNumRequired = true;
        Mevu(mevuContract).changeRandomNumBool();
        Mevu(mevuContract).makeOraclizeQuery("WolframAlpha", strConcat("random number between 0 and ", bytes32ToString(uintToBytes(max))));
    }
    
    function callRandomNum (uint256 max) onlyMevu {
        randomNum(max);
    }


    /** @dev Checks to see if a month (in seconds) has passed since the last lottery paid out, pays out if so    
      */ 
    function checkLottery() onlyMevuContract {       
        if (block.timestamp > Mevu(mevuContract).getNewMonth()) {
            Mevu(mevuContract).addMonth();
            randomNum(Mevu(mevuContract).getOracleListLength()-1);
        }
    }

    
    function uintToBytes(uint v) constant returns (bytes32 ret) {
        if (v == 0) {
            ret = '0';
        }
        else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    function bytes32ToString (bytes32 data) constant returns (string) {
        bytes memory bytesString = new bytes(32);
        for (uint j=0; j<32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[j] = char;
            }
        }
        return string(bytesString);
    } 
}