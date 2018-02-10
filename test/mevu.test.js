const Mevu = artifacts.require("../build/Mevu.sol");
const Events = artifacts.require("../build/Events.sol");
const Admin = artifacts.require("../build/Admin.sol");
const Wagers = artifacts.require("../build/Wagers.sol");
const WagersController = artifacts.require("../build/WagersController.sol");
const CustomWagers = artifacts.require("../build/CustomWagers.sol");
const CustomWagersController = artifacts.require("../build/CustomWagersController.sol");
const Rewards = artifacts.require("../build/Rewards.sol");
const Oracles = artifacts.require("../build/Oracles.sol");
const OraclesController = artifacts.require("../build/OraclesController.sol");
const OracleVerifier = artifacts.require("../build/OracleVerifier.sol");
const MvuToken = artifacts.require("../build/MvuToken.sol");
               
import ether from './helpers/ether';
import { advanceBlock } from './helpers/advanceToBlock';
import { increaseTimeTo, duration } from './helpers/increaseTime';
import latestTime from './helpers/latestTime';
import EVMRevert from './helpers/EVMRevert';

const assertRevert = require('./helpers/assertRevert.js');

const BigNumber = require('bignumber.js');
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))   
  .should();


contract('Mevu', function(accounts) {
   let mevu;
   let events;
   let admin;
   let rewards;
   let oracles;
   let oraclesController;
   let wagers;
   let wagersController;
   let customWagers;
   let customWagersController;
   let oracleVerif;
   let mvuToken; 
   let initialFund = 100000000000000000;

   let balanceA;
   let balanceB;
   let balanceC;

   let afterEventFinished = 1518839239;

    beforeEach('setup contract for each test', async function () {
       mevu = await Mevu.deployed();
       events = await Events.deployed();
       admin = await Admin.deployed();
       wagers = await Wagers.deployed();
       wagersController = await WagersController.deployed();
       customWagers = await CustomWagers.deployed();
       customWagersController = await CustomWagersController.deployed();

       oracleVerif = await OracleVerifier.deployed();
       rewards = await Rewards.deployed();
       oracles = await Oracles.deployed();
       oraclesController = await OraclesController.deployed();

       mvuToken = await MvuToken.deployed();     
    });


//    describe('transferring tokens -- ', function () {
//        it ("should let owner set the wallet address", async function() {               
//            await instance.setMevuWallet(accounts[0]).should.be.fulfilled;                      
//        });

//         it('should prevent non-owners from setting wallet address', async function () {
//             await instance.setMevuWallet(accounts[1], {from:accounts[1]}).should.be.rejectedWith(EVMRevert);         
//         });
//     });

    describe ('setting contracts address & ownership -- ', function (){

        it ("should let owner set Events address", async function() {
            await wagersController.setEventsContract(events.address).should.be.fulfilled;
            await oraclesController.setEventsContract(events.address).should.be.fulfilled;
            await mevu.setEventsContract(events.address).should.be.fulfilled; 
        });

        it ("should let owner set Wagers address", async function() {
            await wagersController.setWagersContract(wagers.address).should.be.fulfilled;
            await mevu.setWagersContract(wagers.address).should.be.fulfilled;  
        });

        it ("should let owner set CustomWagers address", async function() {
            await customWagersController.setCustomWagersContract(customWagers.address).should.be.fulfilled;
            //await mevu.setWagersContract(wagers.address).should.be.fulfilled;  
        });

        it ("should let owner set Admin address", async function() {
            await oraclesController.setAdminContract(admin.address).should.be.fulfilled;
            await wagersController.setAdminContract(admin.address).should.be.fulfilled;
            await customWagersController.setAdminContract(admin.address).should.be.fulfilled;  
            await mevu.setAdminContract(admin.address).should.be.fulfilled;
            await events.setAdminContract(admin.address).should.be.fulfilled;
        });

        it ("should let owner set Oracles address", async function() {
            await oraclesController.setOraclesContract(oracles.address).should.be.fulfilled;
            await mevu.setOraclesContract(oracles.address).should.be.fulfilled; 
            await events.setOraclesContract(oracles.address).should.be.fulfilled; 

        });
      

        it ("should let owner set OracleVerifier address", async function() {
            await oraclesController.setOracleVerifContract(oracleVerif.address).should.be.fulfilled; 
        });

        it ("should let owner set Mevu address", async function() {
            await customWagersController.setMevuContract(mevu.address).should.be.fulfilled;
            await wagersController.setMevuContract(mevu.address).should.be.fulfilled; 
            await oraclesController.setMevuContract(mevu.address).should.be.fulfilled;
            await events.setMevuContract(mevu.address).should.be.fulfilled; 
        });


        it ("should let owner set Rewards address", async function() {
            await customWagersController.setRewardsContract(rewards.address).should.be.fulfilled;
            await wagersController.setRewardsContract(rewards.address).should.be.fulfilled;
            await oraclesController.setRewardsContract(rewards.address).should.be.fulfilled;
            await mevu.setRewardsContract(rewards.address).should.be.fulfilled; 
        });

        it ("should let owner set MvuToken address", async function() {
            await oraclesController.setMvuTokenContract(mvuToken.address).should.be.fulfilled; 
        });

    });


//         it ("should let the owner transfer ownership of rewards to mevu", async function () {
//             await rewards.transferOwnership(instance.address).should.be.fulfilled;
//             let owner = await rewards.owner();
//             owner.should.equal(instance.address);
//         });

//         it ("should let owner set oracles address", async function() {
//             await instance.setOraclesContract(oracles.address).should.be.fulfilled; 
//         });

//         it ("should let the owner transfer ownership of admin to mevu", async function () {
//             await oracles.transferOwnership(instance.address).should.be.fulfilled;
//             let owner = await oracles.owner();
//             owner.should.equal(instance.address);
//         });
     

//         it ("should let owner set wagers address", async function() {
//             await instance.setWagersContract(wagers.address).should.be.fulfilled; 
//         });

//         it ("should let the owner transfer ownership of wagers to mevu", async function () {
//             await wagers.transferOwnership(instance.address).should.be.fulfilled;
//             let owner = await wagers.owner();
//             owner.should.equal(instance.address);
//         });


//          it ("should let owner set Oracle Verifier address", async function() {
//              await instance.setOracleVerifContract(oracleVerif.address).should.be.fulfilled; 
//          });

       
 
    describe('granting authority -- ', function () {
        it ("should let owner grant authority for Rewards", async function() {
            await rewards.grantAuthority(wagersController.address).should.be.fulfilled;
            await rewards.grantAuthority(customWagersController.address).should.be.fulfilled;
            await rewards.grantAuthority(oraclesController.address).should.be.fulfilled;
            await rewards.grantAuthority(mevu.address).should.be.fulfilled;                
        });
        it ("should let owner grant authority for Events", async function() {
            await events.grantAuthority(wagersController.address).should.be.fulfilled;
            await events.grantAuthority(mevu.address).should.be.fulfilled;                     
            await events.grantAuthority(events.address).should.be.fulfilled;               
        });
        it ("should let owner grant authority for Wagers", async function() {
            await wagers.grantAuthority(wagersController.address).should.be.fulfilled;
            await wagers.grantAuthority(mevu.address).should.be.fulfilled;                
        });
        it ("should let owner grant authority for CustomWagers", async function() {
            await customWagers.grantAuthority(customWagersController.address).should.be.fulfilled;
                        
        });
        it ("should let owner grant authority for Oracles", async function() {
            await oracles.grantAuthority(oraclesController.address).should.be.fulfilled;               
        });
        it ("should let owner grant authority for Admin", async function() {
            await admin.grantAuthority(accounts[0]).should.be.fulfilled;
        });
        it ("should let owner grant authority for Mevu", async function() {
            await mevu.grantAuthority(wagersController.address).should.be.fulfilled;
            await mevu.grantAuthority(events.address).should.be.fulfilled;
            await mevu.grantAuthority(oraclesController.address).should.be.fulfilled;
        });
    });

    describe('approving token transfers -- ', function () {
        it ("should let anyone approve transfers from token contract", async function() {
            await mvuToken.approve(oraclesController.address, 5000000000).should.be.fulfilled;           
            await mvuToken.transfer(accounts[1], 1000000000).should.be.fulfilled;
            await mvuToken.transfer(accounts[2], 1000000000).should.be.fulfilled;
            await mvuToken.transfer(accounts[3], 100000000).should.be.fulfilled;
            await mvuToken.transfer(accounts[4], 2000000).should.be.fulfilled;
            await mvuToken.approve(oraclesController.address, 1000000000, {from: accounts[1]}).should.be.fulfilled;
            await mvuToken.approve(oraclesController.address, 1000000000, {from: accounts[2]}).should.be.fulfilled;
            await mvuToken.approve(oraclesController.address, 1000000000, {from: accounts[3]}).should.be.fulfilled;
            await mvuToken.approve(oraclesController.address, 1000000000, {from: accounts[4]}).should.be.fulfilled;
        });
    });


    describe('making and updating events -- ', function () {
        it ("should let owner create events", async function() {              
          
            await events.makeStandardEvent( web3.sha3("test_event2"),
                                              web3.sha3("test_event2"),
                                              1512519349,
                                              6000,                                             
                                              web3.sha3("team1"),
                                               web3.sha3("team2")).should.be.fulfilled;                               
            await events.makeStandardEvent( web3.sha3("test_event3"),
                                              web3.sha3("test_event3"),
                                              1512519349,
                                              6000,                                             
                                              web3.sha3("team1"),
                                              web3.sha3("team2")).should.be.fulfilled;                               
         });
        

        it ("should let owner set min oracle num", async function() {
            await admin.setMinOracleNum (web3.sha3("test_event2"), 3);  
            await admin.setMinOracleNum (web3.sha3("test_event3"), 3);                                
        });       
    }); 
    


    //     it('should prevent non-owners from creating events', async function () {
    //         await instance.makeStandardEvent(web3.sha3("test_event1"),
    //         1512519349,
    //         6000,
    //         web3.sha3("sport"),
    //         web3.sha3("team1"),
    //         web3.sha3("team2"), {from:accounts[1]}).should.be.rejectedWith(EVMRevert);         
    //     });

    //     it ("should let owner update events", async function() { 
    //         await instance.updateStandardEvent(web3.sha3("test_event"),
    //         1512567349,
    //         7000,                                                
    //         web3.sha3("team1"),
    //         web3.sha3("team2"), {from:accounts[0]}).should.be.fulfilled;                      
    //     });

    //     it ("should let owner cancel events", async function() { 
            
    //         await instance.cancelStandardEvent(web3.sha3("test_event")).should.be.fulfilled;
    //         let id = web3.sha3("test_event");            
    //         let locked = await events.getLocked(id);     
    //         locked.should.be.true;
                     
    //     });        
  
    // describe('starting and stopping contract -- ', function () {
       
    //     it ("should let owner start/re-start contract", async function() {                            
    //         await instance.restartContract(10,{value:1000000000000}).should.be.fulfilled;                             
    //     });   

    //     it("should not let a non owner pause contract", async function () {
    //         await instance.pauseContract({from:accounts[1]}).should.be.rejectedWith(EVMRevert);
    //         let paused = await instance.getContractPaused();
    //         paused.should.be.false;          
    //     });
    // });

    describe('making wagers -- ', function () {      
        it ("it should let anyone make a wager", async function () {
            let balanceA =  web3.eth.getBalance(accounts[0]).valueOf();
            await wagersController.makeWager(web3.sha3("wager1") , 10000000000000000, web3.sha3("test_event2"), 100, 1, {value:10000000000000000}).should.be.fulfilled;
            let maker = await wagers.getMaker(web3.sha3("wager1"));
            maker.should.equal(accounts[0]);
            let newBalance =  web3.eth.getBalance(accounts[0]).valueOf();
            let diff = balanceA - newBalance;
            diff.should.be.above(10000000000000000);

            await wagersController.makeWager(web3.sha3("wager2") , 10000000000000000, web3.sha3("test_event2"), 100, 1, {from:accounts[2], value:10000000000000000}).should.be.fulfilled;
        });

        it ("it should let anyone make a custom wager with no judge", async function () {
            let balanceA =  web3.eth.getBalance(accounts[0]).valueOf();
            await customWagersController.makeWager(web3.sha3("wager1"), 1518182608 ,1, 10000000000000000, 100, '0x0000000000000000000000000000000000000000', {value:10000000000000000}).should.be.fulfilled;
            let maker = await customWagers.getMaker(web3.sha3("wager1"));
            maker.should.equal(accounts[0]);
            let newBalance =  web3.eth.getBalance(accounts[0]).valueOf();
            let diff = balanceA - newBalance;
            diff.should.be.above(10000000000000000);

            //await wagersController.makeWager(web3.sha3("wager2") , 10000000000000000, web3.sha3("test_event2"), 100, 1, {from:accounts[2], value:10000000000000000}).should.be.fulfilled;
        });

        it ("should update rewards contract", async function () {
            let bal = await rewards.getEthBalance(accounts[0]).should.be.fulfilled;
            let uBal = await rewards.getUnlockedEthBalance(accounts[0]).should.be.fulfilled;
            uBal.valueOf().should.equal('0');
            bal.valueOf().should.equal('20000000000000000');
        });

        it ("it should let anyone take a wager", async function () {
            await wagersController.takeWager(web3.sha3("wager1"), {from:accounts[1], value:10000000000000000}).should.be.fulfilled;
            let taker = await wagers.getTaker(web3.sha3("wager1"));
            taker.should.equal(accounts[1]);

            await wagersController.takeWager(web3.sha3("wager2"), {from:accounts[3], value:10000000000000000}).should.be.fulfilled;
        });

    //     it ("should not allow a taken wager to be cancelled by maker", async function () {
    //         await wagers.cancelWager(web3.sha3("wager"), true).should.be.rejectedWith(EVMRevert);
    //     });

    //     it ("should allow a taken wager to be requested to cancel by maker", async function () {
    //         await wagers.requestWagerCancel(web3.sha3("wager")).should.be.fulfilled;
    //         let request = await wagers.getMakerCancelRequest(web3.sha3("wager"));
    //         request.should.be.true;
    //         let settled = await wagers.getSettled(web3.sha3("wager"));
    //         settled.should.be.false;
    //     });

    //     it ("should allow a taker to agree to cancel and then refund and settle", async function () {            
    //         await wagers.requestWagerCancel(web3.sha3("wager"), {from:accounts[1]}).should.be.fulfilled;            
    //         let settled = await wagers.getSettled(web3.sha3("wager"));
    //         settled.should.be.true;           
    //     });
    });
  


    // describe('settling wagers -- ', function () {    

    // });

    describe('verifying oracles -- ', function () {   
        it ("should let owner verify an oracle", async function() {
            await oracleVerif.addVerifiedOracle(accounts[0], 5555555555).should.be.fulfilled;
            await oracleVerif.addVerifiedOracle(accounts[1], 5555555556).should.be.fulfilled;
            await oracleVerif.addVerifiedOracle(accounts[2], 5555555557).should.be.fulfilled;
            await oracleVerif.addVerifiedOracle(accounts[3], 5555555558).should.be.fulfilled;
            await oracleVerif.addVerifiedOracle(accounts[4], 5555555559).should.be.fulfilled;
        });
    });

    describe('starting oraclize recursion -- ', function () {   
        
        it ("should let owner start/re-start contract", async function() {                              
            await mevu.restartContract(1,{value:1000000000000}).should.be.fulfilled;                                  
        });   

        it("should not let a non owner pause contract", async function () {
            await mevu.pauseContract({from:accounts[1]}).should.be.rejectedWith(EVMRevert);
            let paused = await mevu.getContractPaused();
            paused.should.be.false;          
        });
    });

    describe('updating events and settling wagers -- ', function () {
        it ("should not be voteReady until the callback", async function() {
            let voteReady = await events.getVoteReady(web3.sha3("test_event2"));
            voteReady.should.equal(false);
        });
        
        it ("should not accept oracle votes before event is voteReady", async function() {
            await oraclesController.registerOracle (web3.sha3("test_event2"), 10, 1).should.be.rejectedWith(EVMRevert);
        });
        
        it ("should make a recently finished event voteReady", async function() {
            wait(28000);          
            let voteReady = await events.getVoteReady(web3.sha3("test_event2"));
            voteReady.should.equal(true); 
            let locked = await events.getLocked(web3.sha3("test_event2"));
            locked.should.equal(false);                 
        });

        it ("should let maker vote", async function () {
            await wagersController.submitVote(web3.sha3("wager1") , 1, {from:accounts[0]}).should.be.fulfilled;
            let vote = await wagers.getMakerWinVote(web3.sha3("wager1"));
            vote.valueOf().should.equal('1');

            await wagersController.submitVote(web3.sha3("wager2") , 1, {from:accounts[2], gasPrice:2000000000}).should.be.fulfilled;
        });

        it ("should let taker vote and do nothing if they disagree", async function () {
           let balance = web3.eth.getBalance(accounts[2]).valueOf();           
           
            await wagersController.submitVote(web3.sha3("wager2") , 2, {from:accounts[3]}).should.be.fulfilled;
            let vote = await wagers.getTakerWinVote(web3.sha3("wager2"));
            vote.valueOf().should.equal('2');

            let newBalance = web3.eth.getBalance(accounts[2]);
            let diff = newBalance - balance;
            diff.should.be.within(0, 100000);
        });  

        it ("should let taker vote and payout winner if they agree", async function () {
            balanceA = web3.eth.getBalance(accounts[0]).valueOf();
           
            await wagersController.submitVote(web3.sha3("wager1") , 1, {from:accounts[1]}).should.be.fulfilled;
            let vote = await wagers.getTakerWinVote(web3.sha3("wager1"));
            vote.valueOf().should.equal('1');

            let newBalance = web3.eth.getBalance(accounts[0]);
            let diff = newBalance - balanceA;
            diff.should.be.within(19000000000000000, 21000000000000000);
        });      

        it("should not have a winner chosen yet", async function () {
            let winner = await events.getWinner(web3.sha3("test_event2")).should.be.fulfilled;
            winner.valueOf().should.equal('0');
        });


        it ("should accept oracle votes and tokens for verified oracles for voteReady event", async function() {
            await oraclesController.registerOracle (web3.sha3("test_event2"), 100000000, 1).should.be.fulfilled;  
            await oraclesController.registerOracle (web3.sha3("test_event2"), 100000000, 1, {from: accounts[1]}).should.be.fulfilled;
            await oraclesController.registerOracle (web3.sha3("test_event2"), 200000000, 2, {from: accounts[2]}).should.be.fulfilled;
            await oraclesController.registerOracle (web3.sha3("test_event2"), 10000000, 2, {from: accounts[3]}).should.be.fulfilled;
            await oraclesController.registerOracle (web3.sha3("test_event2"), 1000000, 1, {from: accounts[4]}).should.be.fulfilled;
            await oraclesController.registerOracle (web3.sha3("test_event2"), 10, 1).should.be.rejectedWith(EVMRevert);

           await oraclesController.registerOracle (web3.sha3("test_event3"), 100000, 1, {from: accounts[4]}).should.be.fulfilled;
        });

        it ("should make a voteReady event locked after another interval", async function() {
            wait(39000);
            let locked = await events.getLocked(web3.sha3("test_event2"));
            locked.should.equal(true);   
               
        });

        it("should have a winner chosen now", async function () {
            let winner = await events.getWinner(web3.sha3("test_event2")).should.be.fulfilled;
            winner.valueOf().should.equal('1');
        });

        it ("should let winner vote again after disagreement to claim win", async function () {
            await wagersController.submitVote(web3.sha3("wager2") , 1, {from:accounts[2], gasPrice:2000000000}).should.be.fulfilled;          
        });

        it ("should update rewards contract after oracle win claim", async function () {
            let bal = await rewards.getEthBalance(accounts[2]).should.be.fulfilled;
            let uBal = await rewards.getUnlockedEthBalance(accounts[2]).should.be.fulfilled;
            uBal.valueOf().should.equal('19400000000000000');
            bal.valueOf().should.equal('19400000000000000');
        });
        
        it ("should let winner withdraw after claiming win", async function () {
            let balance = web3.eth.getBalance(accounts[2]).valueOf();         
            await wagersController.withdraw((19400000000000000), {from:accounts[2], gasPrice:2000000000}).should.be.fulfilled;
            let newBal = web3.eth.getBalance(accounts[2]).valueOf();
            let diff = newBal - balance; 
            //console.log("Balance: " + balance + " NewBal: " + newBal);
            diff.should.be.within(19000000000000000, 21000000000000000);           
        });

        it ("should let oracles claim rewards", async function () {            
            let oUnlMvuBal0 = await rewards.getUnlockedMvuBalance(accounts[0]);            
            let oMvuBal0 = await rewards.getMvuBalance(accounts[0]);            
            let rep0 = await rewards.getOracleRep(accounts[0]);          
            let oUnlEthBal0 = await rewards.getUnlockedEthBalance(accounts[0]);           
          
            oUnlMvuBal0.valueOf().should.equal('0');
            oMvuBal0.valueOf().should.equal('100000000');
            oUnlEthBal0.valueOf().should.equal('0');
            rep0.valueOf().should.equal('0');          

            await oraclesController.claimReward(web3.sha3("test_event2")).should.be.fulfilled;
            await oraclesController.claimReward(web3.sha3("test_event2"), {from: accounts[1]}).should.be.fulfilled;
            await oraclesController.claimReward(web3.sha3("test_event2"), {from: accounts[2]}).should.be.fulfilled;
            await oraclesController.claimReward(web3.sha3("test_event2"), {from: accounts[3]}).should.be.fulfilled;
            await oraclesController.claimReward(web3.sha3("test_event2"), {from: accounts[4]}).should.be.fulfilled;             
        });

        it ("should calculate rewards properly", async function () {
            let oUnlMvuBal0 = await rewards.getUnlockedMvuBalance(accounts[0]);            
            let oMvuBal0 = await rewards.getMvuBalance(accounts[0]);            
            let rep0 = await rewards.getOracleRep(accounts[0]);          
            let oUnlEthBal0 = await rewards.getUnlockedEthBalance(accounts[0]);  
           
            oUnlMvuBal0.valueOf().should.equal('152238550');
            oMvuBal0.valueOf().should.equal('152238550');
            oUnlEthBal0.valueOf().should.equal('149253000000000');
            rep0.valueOf().should.equal('1');
        });

        it ("should let oracle claim refund if not enough oralces", async function () {
            console.log (await rewards.getMvuBalance(accounts[4]));
            await oraclesController.claimRefund(web3.sha3("test_event3"), {from: accounts[4]}).should.be.fulfilled;
            let winner = await events.getWinner(web3.sha3("test_event3"));
            console.log("winner: " + winner);            
        });

    });

    function wait(ms){
        var start = new Date().getTime();
        var end = start;
        while(end < start + ms) {
          end = new Date().getTime();
       }
    }
});