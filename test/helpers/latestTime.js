// Returns the time of the last mined block in seconds
export default async function latest () {
  const BN = web3.utils.BN;
  const block = await web3.eth.getBlock('latest');
  return new BN(block.timestamp);
}
