const Mevu = artifacts.require("../build/Mevu.sol");
const Events = artifacts.require("../build/Events.sol");
const Admin = artifacts.require("../build/Admin.sol");
const Wagers = artifacts.require("../build/Wagers.sol");
const Rewards = artifacts.require("../build/Rewards.sol");
const Oracles = artifacts.require("../build/Oracles.sol");
const OracleVerifier = artifacts.require("../build/OracleVerifier.sol");

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
   let instance;
   let events;
   let admin;
   let rewards;
   let oracles;
   let wagers;
   let oracleVerif; 
   let initialFund = 100000000000000000;

   beforeEach('setup contract for each test', async function () {
       instance = await Mevu.deployed();
       events = await Events.deployed();
       admin = await Admin.deployed();
       wagers = await Wagers.deployed();
       oracleVerif = await OracleVerifier.deployed();
       rewards = await Rewards.deployed();
       oracles = await Oracles.deployed();
     
   });


   describe('transferring tokens -- ', function () {
       it ("should let owner set the wallet address", async function() {               
           await instance.setMevuWallet(accounts[0]).should.be.fulfilled;                      
       });

        it('should prevent non-owners from setting wallet address', async function () {
            await instance.setMevuWallet(accounts[1], {from:accounts[1]}).should.be.rejectedWith(EVMRevert);         
        });
    });

    describe ('setting contracts address & ownership -- ', function (){

        it ("should let owner set events address", async function() {
            await instance.setEventsContract(events.address).should.be.fulfilled; 
        });

        it ("should let the owner transfer ownership of events to mevu", async function () {
            await events.transferOwnership(instance.address).should.be.fulfilled;
            let owner = await events.owner();
            owner.should.equal(instance.address);
        });

        it ("should let owner set admin address", async function() {
            await instance.setAdminContract(admin.address).should.be.fulfilled; 
        });

        it ("should let the owner transfer ownership of admin to mevu", async function () {
            await admin.transferOwnership(instance.address).should.be.fulfilled;
            let owner = await admin.owner();
            owner.should.equal(instance.address);
        });

        it ("should let owner set Rewards address", async function() {
            await instance.setRewardsContract(rewards.address).should.be.fulfilled; 
        });

        it ("should let the owner transfer ownership of rewards to mevu", async function () {
            await rewards.transferOwnership(instance.address).should.be.fulfilled;
            let owner = await rewards.owner();
            owner.should.equal(instance.address);
        });

        it ("should let owner set oracles address", async function() {
            await instance.setOraclesContract(oracles.address).should.be.fulfilled; 
        });

        it ("should let the owner transfer ownership of admin to mevu", async function () {
            await oracles.transferOwnership(instance.address).should.be.fulfilled;
            let owner = await oracles.owner();
            owner.should.equal(instance.address);
        });
     

        it ("should let owner set wagers address", async function() {
            await instance.setWagersContract(wagers.address).should.be.fulfilled; 
        });

        it ("should let the owner transfer ownership of wagers to mevu", async function () {
            await wagers.transferOwnership(instance.address).should.be.fulfilled;
            let owner = await wagers.owner();
            owner.should.equal(instance.address);
        });


         it ("should let owner set Oracle Verifier address", async function() {
             await instance.setOracleVerifContract(oracleVerif.address).should.be.fulfilled; 
         });

       
    });


    // describe('making and updating events -- ', function () {
    //     it ("should let owner create events", async function() {                
    //         await instance.makeStandardEvent( web3.sha3("test_event"),
    //                                           1512519349,
    //                                           6000,
    //                                           web3.sha3("sport"),
    //                                           web3.sha3("team1"),
    //                                           web3.sha3("team2")).should.be.fulfilled;
    //                                           await instance.makeStandardEvent( web3.sha3("test_event2"),
    //                                           1512519349,
    //                                           6000,
    //                                           web3.sha3("sport"),
    //                                           web3.sha3("team1"),
    //                                           web3.sha3("team2")).should.be.fulfilled;                               
    //     });
 
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
    // }); 
    
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

    // describe('making wagers -- ', function () {
    //     it ("it should let anyone make a wager", async function () {
    //         await wagers.makeWager(web3.sha3("wager") , 1000000, web3.sha3("test_event2"), 100, 1, {value:1000000}).should.be.fulfilled;
    //         let maker = await wagers.getMaker(web3.sha3("wager"));
    //         maker.should.equal(accounts[0]);
    //     });

    //     it ("it should let anyone take a wager", async function () {
    //         await wagers.takeWager(web3.sha3("wager"), {from:accounts[1], value:1000000}).should.be.fulfilled;
    //         let taker = await wagers.getTaker(web3.sha3("wager"));
    //         taker.should.equal(accounts[1]);
    //     });

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
    // });


  

});