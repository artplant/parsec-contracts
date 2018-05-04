pragma solidity 0.4.16;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}


contract ParsecTokenERC20 {
    // Public variables of the token
    string public constant name = "Parsec Credits";
    string public constant symbol = "PRSC";
    uint8 public decimals = 6;
    uint256 public initialSupply = 30856775800;
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function ParsecTokenERC20() public {
        // Update total supply with the decimal amount
        totalSupply = initialSupply * 10 ** uint256(decimals);

        // Give the creator all initial tokens
        balanceOf[msg.sender] = totalSupply;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);

        // Check if the sender has enough
        require(balanceOf[_from] >= _value);

        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);

        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        // Subtract from the sender
        balanceOf[_from] -= _value;

        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);

        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // Check allowance
        require(_value <= allowance[_from][msg.sender]);

        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        // Check if the sender has enough
        require(balanceOf[msg.sender] >= _value);

        // Subtract from the sender
        balanceOf[msg.sender] -= _value;

        // Updates totalSupply
        totalSupply -= _value;

        // Notify clients about burned tokens
        Burn(msg.sender, _value);

        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        // Check if the targeted balance is enough
        require(balanceOf[_from] >= _value);

        // Check allowance
        require(_value <= allowance[_from][msg.sender]);

        // Subtract from the targeted balance
        balanceOf[_from] -= _value;

        // Subtract from the sender's allowance
        allowance[_from][msg.sender] -= _value;

        // Update totalSupply
        totalSupply -= _value;

        // Notify clients about burned tokens
        Burn(_from, _value);

        return true;
    }
}


contract ParsecTekInvestorRewards is owned {
    /// @notice Use OpenZeppelin's SafeMath
    using SafeMath for uint256;

    // ------------------------
    // --- Input parameters ---
    // ------------------------

    /// @notice Parsec ERC20 token address (from previously deployed contract)
    ParsecTokenERC20 private parsecToken;

    // ---------------------------
    // --- Power-up parameters ---
    // ---------------------------

    /// @notice Minimal amount of Parsecs to cover all rewards
    uint256 public constant MINIMAL_AMOUNT_OF_PARSECS = 290563097000000;    // 290,563,097.000000 PRSC

    /// @notice Keep track if contract is powered up (has enough Parsecs)
    bool public contractPoweredUp = false;

    // ------------------------------------
    // --- Reward batch transfer state  ---
    // ------------------------------------

    /// @notice Keep track if batch 1 / 3 is transferred
    bool public batch1Transferred = false;

    /// @notice Keep track if batch 2 / 3 is transferred
    bool public batch2Transferred = false;

    /// @notice Keep track if batch 3 / 3 is transferred
    bool public batch3Transferred = false;

    // ------------------------
    // --- Parsecs tracking ---
    // ------------------------

    /// @notice Keep track of total transferred rewards
    uint256 public totalTransferredRewards;

    /// @notice Keep track of all transferred rewards
    mapping (address => uint256) public rewardOf;
    
    // --------------
    // --- Events ---
    // --------------

    /// @notice Log an event for each transferred reward
    event LogReward(address indexed sender, uint256 value, uint256 timestamp);

    /**
     * Constructor function
     *
     * Initializes smart contract
     *
     * @param _tokenAddress The address of the previously deployed ParsecTokenERC20 contract
     */
    function ParsecTekInvestorRewards (address _tokenAddress) public {
        // Get Parsec ERC20 token instance
        parsecToken = ParsecTokenERC20(_tokenAddress);
    }

    /// @notice Check if contract has enough Parsecs to cover hard cap
    function ownerPowerUpContract() external onlyOwner {
        // Contract should not be powered up previously
        require(!contractPoweredUp);

        // Contract should have enough Parsec credits
        require(parsecToken.balanceOf(this) >= MINIMAL_AMOUNT_OF_PARSECS);

        // Raise contract power-up flag
        contractPoweredUp = true;
    }

    /// @notice Owner can withdraw Parsecs anytime
    function ownerWithdrawParsecs(uint256 value) external onlyOwner {
        // Get smart contract balance in Parsecs
        uint256 parsecBalance = parsecToken.balanceOf(this);

        // Amount of Parsecs to withdraw should not exceed total balance in Parsecs
        require(value > 0);
        require(value <= parsecBalance);

        // Transfer parsecs
        parsecToken.transfer(owner, value);
    }

    /// @notice Transfer reward batch 1 / 3
    function ownerTransferBatch1() external onlyOwner {
        // Contract should be powered up
        require(contractPoweredUp);

        // Reward batch should not be transferred previously
        require(!batch1Transferred);

        // Perform transfers
        transferParsecs(0x0c42cf7872102426a66f4a40877bba1fde390edc, 1934205000000);
        transferParsecs(0x27c52ed9779bb753c0407a5b020d4c2376c92778, 851760000000);
        transferParsecs(0x5552667e1d85f860dC2a89754E1729B118950cef, 17745000000000);
        transferParsecs(0xaf885fD3927b3D4a14E0A1ebECC2576e6b2f9C0c, 1773698000000);
        transferParsecs(0x1Cf49A2c24656ce6be770C92f2Cbef871A247f51, 1774500000000);
        transferParsecs(0x7bdea2cb78851ebe8f7d20cf627b2dbec1ea1a26, 2720663000000);
        transferParsecs(0x2576c1ea5b7f3418fd93a36c04091b20a0b3b3ea, 10292100000000);
        transferParsecs(0xecaca160e4a1cf13b7dd9b9a5d8732543e6fb2b2, 2642266000000);
        transferParsecs(0x1578416c880a0f282bac17c692b2a80b4336d29b, 1774500000000);
        transferParsecs(0xe72eed5e415f943cba02e3d411265ecdb05f6763, 2750475000000);
        transferParsecs(0x2e73957084186c6882948ebfa450ed363a1b3612, 2661750000000);
        transferParsecs(0xfbf98d46fb905093899f9269401f5f7ecd004303, 1774500000000);
        transferParsecs(0x9defb6a85680e11b6ad8ad4095e51464bb4c0c66, 887250000000);
        transferParsecs(0xd1172888469feba98ee540a2d75478d17c8c3d85, 3549000000000);
        transferParsecs(0x31b5d1bf4da83e24b83e8dd2caa2051c2c986809, 887250000000);
        transferParsecs(0x4D735d4ff74Bda96980Df22860fa83ae39c1394B, 875647000000);
        transferParsecs(0x5c39CFDbd22e862cA8954b16f1E0117B7E907caa, 4359217000000);
        transferParsecs(0x84E77F101773b553bFDb15192e4BEae8d9039AE8, 1751294000000);
        transferParsecs(0x30b2dD9B73Db8d63a490Bd8fa228b0A4f4eB5e5D, 1908689000000);
        transferParsecs(0xcc416c196aEcB528b327684329073cC992F0Cc55, 13176741000000);
        transferParsecs(0xf97239D6615B5173F37B80bb9e208Ad13a24A7f2, 5726068000000);
        transferParsecs(0x2b34C134042c793ff7d2bbB3A4eBaF9a3F5a9eEb, 2182092000000);
        transferParsecs(0x546076E7aB157a7121dDD4562121A5A859A0cdAa, 5231061000000);
        transferParsecs(0x71563016d2E4cE03E4D8A6907C2A7B0Ba79fE983, 3502588000000);
        transferParsecs(0xD2D274c7BA942e522a1b38487Dc265633bcD43E1, 3817379000000);
        transferParsecs(0x696F1D4C0eF2d88FA0a89CBb2d6E57F798d00286, 954345000000);
        transferParsecs(0x6aCe5f92D88822AD6d2A847574B8f29cBec6CF64, 5253882000000);
        transferParsecs(0x8b8bb824B908B10fF5e244cb1F8916959d2Cc2dd, 1908689000000);
        transferParsecs(0x180F8fDf08B9282d9281e739596d26272207004C, 5726068000000);
        transferParsecs(0xA2DF536Df4b46578afeE6671e18dc7C4BAEa98C0, 954345000000);

        // Mark reward batch as transferred
        batch1Transferred = true;
    }

    /// @notice Transfer reward batch 2 / 3
    function ownerTransferBatch2() external onlyOwner {
        // Contract should be powered up
        require(contractPoweredUp);

        // Reward batch should not be transferred previously
        require(!batch2Transferred);

        // Perform transfers
        transferParsecs(0xB45B2FCfD8d9d62a4d80B888a14436e4Fd6773B3, 4771723000000);
        transferParsecs(0xaf837bAd822F0e9bdfE58215E30D5A4411C6D358, 2626941000000);
        transferParsecs(0xc53dAe58910eb59d4746e6615C3e170cEa7c3D79, 4378235000000);
        transferParsecs(0xbD19ed780Ae58A0C2878Ed21C6Ea632713fb2084, 2863034000000);
        transferParsecs(0x2f31556DFbb452Ff08014BBBDD1B0138D6AfBC47, 4771723000000);
        transferParsecs(0x679Cb2c48F83A93F69E93d3cC7a54d74bAAae2Ee, 3817379000000);
        transferParsecs(0x4e843C72D30C9B818166f399cFab07BfE15BdA2A, 1756899000000);
        transferParsecs(0xae7ea559fbC440467F70e3cDC33eA849779aEf55, 1756899000000);
        transferParsecs(0x7E50A8A768b4bFaD4Fd6f326847DcAbae964c989, 1908689000000);
        transferParsecs(0x79B70658839b2423A0ADA3e8bfc3eFF5Ec2addF8, 1526951000000);
        transferParsecs(0xC89d1741E8c2CB12518EadC620e30AA2760FACA1, 4392247000000);
        transferParsecs(0xe1a545fE99286bAD74045082871E53A3136ca1Dc, 875647000000);
        transferParsecs(0xe393f6c5ef14b1C38EdD1D0080AF88Dc7f5eCF10, 1908689000000);
        transferParsecs(0x359Eb6Fe954eA5F926Bca2c22e774Dc5Cf41F177, 1336083000000);
        transferParsecs(0xAfB18464eb052c37829b7847CB60379123460fac, 1751294000000);
        transferParsecs(0x3617c8ef21b1Ac82a24577c15C0c9Ad7e64c32BE, 2863034000000);
        transferParsecs(0x730bb98EBa0Aa70608A06C18392CCE4293cf8713, 3817379000000);
        transferParsecs(0x764dAB024dB5335Ed3bD2f32B1Aa1640F1439EcE, 1908689000000);
        transferParsecs(0x7eCE8938C59061BEF74B3966e98E52c928287fa0, 878449000000);
        transferParsecs(0x7442D491600832B09d77514F86262076B22A16Bc, 954345000000);
        transferParsecs(0x8a1910bE810Ac0a89BbCEE37Db628c9F684a5266, 3502588000000);
        transferParsecs(0x75C6Ff0F84aDBe3290Ddf47f75C45C83409E89A3, 1908689000000);
        transferParsecs(0x60a0f506283eB649A6B8Fb78F28769908736F22d, 1751294000000);
        transferParsecs(0xd6D9535CB9Bcf8b67B4966d92e441bCB81e97798, 7005176000000);
        transferParsecs(0xBD44B401cDE1442DdF3330331ccd2f8aF57cC1fe, 1908689000000);
        transferParsecs(0xe6AD877C05e77b59EF41225f1D2C39b02eB5c819, 4771723000000);
        transferParsecs(0x59e80758b050A44a02a686C7F8a44e0426195BD5, 1908689000000);
        transferParsecs(0xc1BcD6a45E007d6E67E05186ae0Ffce1Db563e09, 3513798000000);
        transferParsecs(0xc64C56288B2bb41BcE11c42FEcD0e30d5D04F028, 1751294000000);
        transferParsecs(0x5203CDD1D0b8cDc6d7CF60228D0c7E7146642405, 954345000000);

        // Mark reward batch as transferred
        batch2Transferred = true;
    }

    /// @notice Transfer reward batch 3 / 3
    function ownerTransferBatch3() external onlyOwner {
        // Contract should be powered up
        require(contractPoweredUp);

        // Reward batch should not be transferred previously
        require(!batch3Transferred);

        // Perform transfers
        transferParsecs(0xbe14a6cC04a4762C97f6F4CcFed7f6F1A77B90F0, 1908689000000);
        transferParsecs(0xA1a5A68eD050D3F48eD9a86d92b0233914487860, 7634757000000);
        transferParsecs(0xea687049A2F133FC954fB5eD6c4514BC18aeA82C, 1054139000000);
        transferParsecs(0x586d1f165B7b6bdfA0A58A199C5347dC3d8221aC, 4378235000000);
        transferParsecs(0x5041e0Bd8Ecdc8ef671Ef6cb298E0601dFa4f053, 5231061000000);
        transferParsecs(0xf3eaf6dd9bd04d2be2231b1bebd40b72270ad9c7, 3487374000000);
        transferParsecs(0xE8b533cC635552377f173496494699b65876CF38, 1908689000000);
        transferParsecs(0x1eafcd719127f9A3a049D2504B6fE6aB61a877C5, 1908689000000);
        transferParsecs(0x44F7768b0B0cbFd1d9Fa802f9f41f81EE4b2A2bB, 1743687000000);
        transferParsecs(0xC3C93993CbF0CD362884f1DBc66d9f9c30fb2d8b, 7723286000000);
        transferParsecs(0x1bF2c0B51dBbd4bF3A9eDFA87d7A65160618F79b, 1751294000000);
        transferParsecs(0x69a1a79e9359044283f6afb907a3c475b82d6fcd, 871843000000);
        transferParsecs(0x9907108408bce813512E4FB79aa75d902461a078, 1756899000000);
        transferParsecs(0xd2185f555cd30133194d04ba08253372A3A521ae, 5253882000000);
        transferParsecs(0x9042b468cEC53aA0FdaBb7b184ED4081ECC749cF, 871843000000);
        transferParsecs(0x352EaDC085d0fC7C79B5B0460B5C688B7dC41769, 1908689000000);
        transferParsecs(0x654615176F7AE60CfBCAd3cEc1Eaf4a147339f59, 875647000000);
        transferParsecs(0x8d6BF48718D7e54A174a417bc0806e71181b7b58, 3817379000000);
        transferParsecs(0x10f7147802C8c0896b707924db48aa9D46a6BF0B, 5726068000000);
        transferParsecs(0x9b0B33aAe7C136d8Fd2A787FaAd7e3b9a629973A, 871843000000);
        transferParsecs(0xDCa16f182bF6a69890859279433f7E97E2015907, 3502588000000);
        transferParsecs(0xa43e3a8C9a58080313AaEfe607f4115676811a38, 1908689000000);
        transferParsecs(0x3aB7D6753eA832Dddd0869d9FFE5139e1f3e1839, 17512940000000);
        transferParsecs(0x25C3D8fe9c18F9203Fe399CCA82AB90FD5AB63CE, 5253882000000);
        transferParsecs(0x73A74B1E90C8301813379d7b77a2cfbD90D8B277, 3502588000000);
        transferParsecs(0x36E8048CB3Ce54F9Eaa71f837dF20b87a5C54EA9, 1756899000000);
        transferParsecs(0x3Df760F2299E9AbEB4fb4CDA0845b2206526955B, 5253882000000);

        // Mark reward batch as transferred
        batch3Transferred = true;
    }

    /// @dev Transfer reward in Parsecs
    function transferParsecs(address participant, uint256 value) private {
        // Participant's reward is increased by value
        rewardOf[participant] = rewardOf[participant].add(value);

        // Increase total transferred reward
        totalTransferredRewards = totalTransferredRewards.add(value);

        // Log an event of the participant's reward
        LogReward(participant, value, now);

        // Transfer Parsecs
        parsecToken.transfer(participant, value);
    }
}