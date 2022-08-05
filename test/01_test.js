const token = artifacts.require("MyToken");
const truffleAssert = require("truffle-assertions");

const Web3 = require("web3");
const web3 = new Web3("http://127.0.0.1:8545");


contract("OATImplementation", (accounts) => {
  before(async () => {
    this.mytoken = await token.new("Token", "TO");
  });
  describe("minting", async () => {
    it("can create token", async () => {
        // this.testtoken = await token.new("Token", "TO");
        const result = await this.mytoken.safeMint(accounts[1],"Test URI" );
        truffleAssert.eventEmitted(result, "TokenMinted");
      
    });
  
    });
});
