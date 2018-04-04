const Mevu = artifacts.require("./build/Mevu.sol");
const Admin = artifacts.require("./build/Admin.sol");
const Events = artifacts.require("./build/Events.sol");
const EventsController = artifacts.require("../build/EventsController.sol");
const Wagers = artifacts.require("./build/Wagers.sol");
const WagersController = artifacts.require("./build/WagersController.sol");
const CustomWagers = artifacts.require("./build/CustomWagers.sol");
const CustomWagersController = artifacts.require("./build/CustomWagersController.sol");
const Rewards = artifacts.require("./build/Rewards.sol");
const OracleVerifier = artifacts.require("./build/OracleVerifier.sol");
const Oracles = artifacts.require("./build/Oracles.sol");
const OraclesController = artifacts.require("./build/OraclesController.sol");
const MvuToken = artifacts.require("./build/MvuToken.sol");
const CancelController = artifacts.require("./build/CancelController.sol");

module.exports = (deployer, network, accounts) => {    
    let deployAddress = accounts[0];    
    let totalSupply = 500000000000;  
    let gasLimit = 6900000;
    var admin, mevu, events, eventsController, oracles, oraclesController, oracleVerifier, wagers, wagersController, customWagers, customWagersController, cancelController, rewards, mvuToken;
    
    deployer.deploy(Oracles,  {from: deployAddress, gas:gasLimit});
    deployer.deploy(OraclesController,  {from: deployAddress, gas:gasLimit});
    deployer.deploy(Admin,  {from: deployAddress, gas:gasLimit});
    deployer.deploy(Events,  {from: deployAddress, gas:gasLimit});
    deployer.deploy(EventsController, {from: deployAddress, gas: gasLimit});
    deployer.deploy(OracleVerifier,  {from: deployAddress, gas:gasLimit});
    deployer.deploy(Wagers,  {from: deployAddress, gas:gasLimit});
    deployer.deploy(WagersController,  {from: deployAddress, gas:gasLimit});
    deployer.deploy(CustomWagers,  {from: deployAddress, gas:gasLimit});
    deployer.deploy(CustomWagersController,  {from: deployAddress, gas:gasLimit});
    deployer.deploy(CancelController,  {from: deployAddress, gas:gasLimit});
    deployer.deploy(Rewards, {from: deployAddress, gas:gasLimit});
    deployer.deploy(Mevu,  {from: deployAddress, gas:gasLimit});
    deployer.deploy(MvuToken, totalSupply,  {from: deployAddress, gas:gasLimit});

    deployer.then(function() {   
       return Mevu.deployed();
    }).then(function(instance) {
        mevu = instance;
        return Events.deployed();
    }).then(function(instance) {
        events = instance;
        return mevu.setEventsContract(events.address);   
    }).then(function() {       
        return Admin.deployed();
    }).then(function(instance) {
        admin = instance;
        return mevu.setAdminContract(admin.address);   
    }).then(function(){
        return events.setAdminContract(admin.address);
    }).then(function(){
        return events.setMevuContract(mevu.address);
    }).then(function(){
        return Oracles.deployed();
    }).then(function(instance) {
        oracles = instance; 
        return events.setOraclesContract(oracles.address);
    }).then(function(){ 
        return mevu.setOraclesContract(oracles.address);
    }).then(function(){ 
        return MvuToken.deployed();
    }).then(function(instance) {
        mvuToken = instance;
        return OraclesController.deployed();
    }).then(function(instance){
        oraclesController = instance;
        return oraclesController.setOraclesContract(oracles.address);
    }).then(function(){ 
        return oraclesController.setAdminContract(admin.address);
    }).then(function(){ 
        return oraclesController.setEventsContract(events.address);
    }).then(function(){ 
        return oraclesController.setMevuContract(mevu.address);
    }).then(function(){ 
        return oraclesController.setMvuTokenContract(mvuToken.address);
    }).then(function(){ 
        return OracleVerifier.deployed();
    }).then(function(instance){
        oracleVerifier = instance;
        oraclesController.setOracleVerifContract(oracleVerifier.address);
    }).then(function(){ 
        return Rewards.deployed();
    }).then(function(instance){
        rewards = instance;
        return oraclesController.setRewardsContract(rewards.address);
    }).then(function(){
        return mevu.setRewardsContract(rewards.address);
    }).then(function(){
        return Wagers.deployed();
    }).then(function(instance){
        wagers = instance;
        return WagersController.deployed();
    }).then(function(instance){
        wagersController = instance;
        return wagersController.setAdminContract(admin.address);
    }).then(function(){
        return wagersController.setWagersContract(wagers.address);
    }).then(function(){
        return wagersController.setEventsContract(events.address);
    }).then(function(){
        return wagersController.setMevuContract(mevu.address);
    }).then(function(){
        return mevu.setWagersContract(wagers.address);
    }).then(function(){
        return wagersController.setRewardsContract(rewards.address);
    }).then(function(){
        return mevu.setRewardsContract(rewards.address);
    }).then(function(){
        return CancelController.deployed();
    }).then(function(instance){
        cancelController = instance;
        return cancelController.setWagersContract(wagers.address);
    }).then(function(){
        return cancelController.setMevuContract(mevu.address);
    }).then(function(){
        return CustomWagers.deployed();
    }).then(function(instance){
        customWagers = instance;
        return CustomWagersController.deployed();
    }).then(function(instance){
        customWagersController = instance;
        return customWagersController.setCustomWagersContract(customWagers.address);
    }).then(function(){
        return cancelController.setCustomWagersContract(customWagers.address);
    }).then(function(){
        return customWagersController.setAdminContract(admin.address);
    }).then(function(){
        return customWagersController.setMevuContract(mevu.address);
    }).then(function(){
        return customWagersController.setRewardsContract(rewards.address);
    }).then(function(){
        return cancelController.setMevuContract(mevu.address);
    }).then(function(){
        return cancelController.setRewardsContract(rewards.address);
    }).then(function(){
        return rewards.grantAuthority(wagersController.address);
    }).then(function(){
        return rewards.grantAuthority(customWagersController.address);
    }).then(function(){
        return rewards.grantAuthority(oraclesController.address);
    }).then(function(){
        return rewards.grantAuthority(cancelController.address);
    }).then(function(){
        return rewards.grantAuthority(mevu.address);
    }).then(function(){
        return events.grantAuthority(wagersController.address);
    }).then(function(){
        return events.grantAuthority(mevu.address);
    }).then(function(){
        return events.grantAuthority(events.address);
    }).then(function(){
        return wagers.grantAuthority(mevu.address);
    }).then(function(){
        return wagers.grantAuthority(cancelController.address);
    }).then(function(){
        return wagers.grantAuthority(wagersController.address);
    }).then(function(){
        return customWagers.grantAuthority(customWagersController.address);
    }).then(function(){
        return customWagers.grantAuthority(cancelController.address);
    }).then(function(){
        return oracles.grantAuthority(oraclesController.address);
    }).then(function(){
        return admin.grantAuthority(deployAddress);
    }).then(function(){
        return oracleVerifier.grantAuthority(deployAddress);
    }).then(function(){
        return mevu.grantAuthority(wagersController.address);
    }).then(function(){
        return mevu.grantAuthority(oraclesController.address);
    }).then(function(){
        return mevu.grantAuthority(cancelController.address);
    }).then(function(){
        return mevu.grantAuthority(events.address);
    }).then(function(){
        return EventsController.deployed();
    }).then (function (instance) {
        eventsController = instance;
        return events.grantAuthority(eventsController.address);
    }).then(function(){
        return mevu.grantAuthority(eventsController.address);
    }).then(function(){
        return eventsController.setEventsContract(events.address);         
    }).then(function () {
        return eventsController.setOracleVerifierContract(oracleVerifier.address);
    }).then(function () {
        return eventsController.setAdminContract(admin.address);
    }).then(function() {
        return eventsController.setMevuContract(mevu.address);
    });

   

    
    
    
  
};
