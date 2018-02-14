pragma solidity 0.4.18;

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

/**
 * @title Parsec Frontiers bounty reward contract
 *
 * @author Maxim Pushkar
 */
contract ParsecBounty is owned {
    // Use OpenZeppelin's SafeMath
    using SafeMath for uint256;

    // Claim period. During this period the registered accounts can claim their Parsec credits
    uint256 public constant CLAIM_START_DATE = 1525176000;              // 2018-05-01 12:00:00 UTC
    uint256 public constant CLAIM_END_DATE = 1533124800;                // 2018-08-01 12:00:00 UTC

    // Amount of Parsec credits required for all bounties
    uint256 public constant REQUIRED_CREDITS_AMOUNT = 400000000000000;  // 400000000.000000 PRSC

    // Keep track of total amount of Parsec credits to be claimed
    uint256 public totalAmountToClaim;

    // Keep track of amount of Parsec credits actually claimed
    uint256 public actuallyClaimedAmount;

    // Keep track if contract is powered up
    bool public contractPoweredUp = false;

    // Keep track if bounty chunk 1 / 3 is already added
    bool public chunk1IsAdded = false;

    // Keep track if bounty chunk 2 / 3 is already added
    bool public chunk2IsAdded = false;

    // Keep track if bounty chunk 3 / 3 is already added
    bool public chunk3IsAdded = false;

    // Keep track of all registered bounties
    mapping (address => uint256) public bountyOf;

    // Parsec ERC20 token contract (from previously deployed address)
    ParsecTokenERC20 private parsecToken;

    // Log an event for each claimed bounty during the claim period
    event LogBountyClaim(address indexed sender, uint256 value, uint256 timestamp);  

    function ParsecBounty (address tokenAddress) public {
        // Get Parsec ERC20 token instance
        parsecToken = ParsecTokenERC20(tokenAddress);
    }

    /// @notice Add bounty chunk 1 / 3
    function addBountyChunk1() external onlyOwner {
        // Bounty chunk can be added only once
        require(!chunk1IsAdded);

        // Register bounties
        registerBounty(0x254E9475169B5b1681e0E282476a764CfEe303C9, 38199052000000);
        registerBounty(0xfD854E01dDadAa35F64fC1C491347963B6562D2D, 43127962000000);
        registerBounty(0x9c99eeB6a3CC8aC6Dcf8575575BbCff7a0D87896, 34502370000000);
        registerBounty(0xCBC8Bbf61326422067A17D31a1daF33e8f0B70c8, 11090047000000);
        registerBounty(0x9fEFd6C32E435435921be98D5251A35EB4B9339d, 2843602000000);
        registerBounty(0x2CCE6c9D6a95A8fa8485578119b399b1759e6292, 2843602000000);
        registerBounty(0xC7E98A1f2F749B9737878748DDf971EA3234077d, 7393365000000);
        registerBounty(0x4230D0704cDDd9242A0C98418138Dd068D52c8A1, 4476534000000);
        registerBounty(0xD896714537310f20DB563Ae28E7226e4fBE2ceE2, 8086643000000);
        registerBounty(0x542F72DC468606877877Ce971deCe03C9bEB67d5, 5054152000000);
        registerBounty(0x9BDbEb5F6E59dd471Bc296B97266D3Ee634B7c7e, 6209386000000);
        registerBounty(0x84c10c798ee82D4b8Cf229E40267e6efa9BbF6Dd, 722022000000);
        registerBounty(0x72a5b7Fc75DC27f9Da2748373b07a883896411f3, 3465704000000);
        registerBounty(0x2DABBC7db7a6bF55B1356AFacBCc882a32301c55, 1155235000000);
        registerBounty(0x11D1e70F657399bAAd0849Edd93a2F52cb5f35F9, 1877256000000);
        registerBounty(0x91AA1bF579cf66847d833925F77e26237fdFcA91, 2021661000000);
        registerBounty(0xC50CD9c617cF4095533578236CFeAE149EFbcE87, 1732852000000);
        registerBounty(0x9E1216e6731D66F22DE9115A6A363aDF76D913CE, 1299639000000);
        registerBounty(0xaaf48F8743C985D3191508C066799Ebed00Dc0d8, 1155235000000);
        registerBounty(0xD3ec5A07125761494B38aE7c67e6D203dD419aae, 866426000000);
        registerBounty(0x8194A6A9f0B2fE02344FCd7F41DdFAb6539fB52F, 577617000000);
        registerBounty(0x9D3afA524B87Ba0a3b0907d3dF879d4b8F044A73, 866426000000);
        registerBounty(0xf539d423E2175B7cD82061eff7072C328B309230, 433213000000);
        registerBounty(0xfd052EC542Db2d8d179C97555434C12277a2da90, 4003984000000);
        registerBounty(0x4230D0704cDDd9242A0C98418138Dd068D52c8A1, 2450199000000);
        registerBounty(0xCFe1Bd70Ae72B9c7BC319f94c512D8f96FCcb4C8, 3466135000000);
        registerBounty(0xDdE12A1B5718D002e8AC78216720Eb9BF3C6DBFb, 4541833000000);
        registerBounty(0x542F72DC468606877877Ce971deCe03C9bEB67d5, 3167331000000);
        registerBounty(0x31a570a588DC86fAeB45057e749533FB0cD9622d, 358566000000);
        registerBounty(0x9BDbEb5F6E59dd471Bc296B97266D3Ee634B7c7e, 2749004000000);
        registerBounty(0x84c10c798ee82D4b8Cf229E40267e6efa9BbF6Dd, 1135458000000);
        registerBounty(0xD896714537310f20DB563Ae28E7226e4fBE2ceE2, 2310757000000);
        registerBounty(0x9B6286cb7D58c90Ca49B5B6900C5A3B98f5f77cd, 139442000000);
        registerBounty(0x9BE1c7a1F118F61740f01e96d292c0bae90360aB, 597610000000);
        registerBounty(0x123422Cf323c57DE45361d361e6C8AB3B8391503, 1254980000000);
        registerBounty(0x72a5b7Fc75DC27f9Da2748373b07a883896411f3, 1613546000000);
        registerBounty(0x2DABBC7db7a6bF55B1356AFacBCc882a32301c55, 1015936000000);
        registerBounty(0x11D1e70F657399bAAd0849Edd93a2F52cb5f35F9, 1254980000000);
        registerBounty(0x3F0CFF7cb4fF4254031BcEf80412e4Cafe4AeC7A, 1314741000000);
        registerBounty(0x91AA1bF579cf66847d833925F77e26237fdFcA91, 1195219000000);
        registerBounty(0xc33818c89F58802E3c1e28867d699a0f9AdA4a76, 1135458000000);
        registerBounty(0x38b324834410f17D236d9f885370289201cF948F, 776892000000);
        registerBounty(0xC50CD9c617cF4095533578236CFeAE149EFbcE87, 836653000000);
        registerBounty(0xC38e638025e22A046c7FCe29e56F628906f9d040, 836653000000);
        registerBounty(0x9E1216e6731D66F22DE9115A6A363aDF76D913CE, 836653000000);
        registerBounty(0x3AA113B6852E60a4C2ba115dfcd4951daeC57c78, 358566000000);
        registerBounty(0xaaf48F8743C985D3191508C066799Ebed00Dc0d8, 836653000000);
        registerBounty(0x6617503541FD6CF5548820A4FdE7b14211397206, 836653000000);
        registerBounty(0xD3ec5A07125761494B38aE7c67e6D203dD419aae, 418327000000);
        registerBounty(0xD97566a98b9bCedC60f8814114AC371e3abA33E8, 358566000000);
  
        // Raise chunk added flag
        chunk1IsAdded = true;
    }

    /// @notice Add bounty chunk 2 / 3
    function addBountyChunk2() external onlyOwner {
        // Bounty chunk can be added only once
        require(!chunk2IsAdded);

        // Register bounties
        registerBounty(0x9D3afA524B87Ba0a3b0907d3dF879d4b8F044A73, 199203000000);
        registerBounty(0xc97078d9ecc953a8e263626892da1f17579fa6e6, 4800000000000);
        registerBounty(0xc97078d9ecc953a8e263626892da1f17579fa6e6, 7200000000000);
        registerBounty(0x448202bf8a049460bfa60527daca2ff3d47294b4, 7200000000000);
        registerBounty(0x9286d9DeD3Bb4C4CE54e10A8c484e190dA455696, 7200000000000);
        registerBounty(0x1B55887509d4d07965e20842cddaA1B1C4AD559c, 19200000000000);
        registerBounty(0xaC340Cbf45502e509ffC5F213c882516C964202A, 7200000000000);
        registerBounty(0x4638f2cB0CF6d864f351a06d068e4aFb642FAfa2, 7200000000000);
        registerBounty(0x5325D89F64FA6B93C06DB2E6f6d1E672Cffb15fe, 1666667000000);
        registerBounty(0x95D4914d4f08732A169367674A8BE026c02c5B44, 10000000000000);
        registerBounty(0x70580eA14d98a53fd59376dC7e959F4a6129bB9b, 6666669000000);
        registerBounty(0x387c71683A05Cdf4Df2ccd861ad4eeD16F09F917, 1666667000000);
        registerBounty(0xB87e73ad25086C43a16fE5f9589Ff265F8A3A9Eb, 6666667000000);
        registerBounty(0xA443838ad905148232F78F9521577c38932cd832, 5333333000000);
        registerBounty(0x95d4914d4f08732a169367674a8be026c02c5b44, 8000000000000);
        registerBounty(0x237706bfE11D4C4E148b4764c8f7Da37743657d4, 1161525000000);
        registerBounty(0x9B6286cb7D58c90Ca49B5B6900C5A3B98f5f77cd, 871143000000);
        registerBounty(0x28687f8Ae963a33db8fC94C04e231083bd18Af4F, 871143000000);
        registerBounty(0x387c71683A05Cdf4Df2ccd861ad4eeD16F09F917, 2177858000000);
        registerBounty(0x70580eA14d98a53fd59376dC7e959F4a6129bB9b, 290381000000);
        registerBounty(0x387c71683A05Cdf4Df2ccd861ad4eeD16F09F917, 2177858000000);
        registerBounty(0x3F0CFF7cb4fF4254031BcEf80412e4Cafe4AeC7A, 871143000000);
        registerBounty(0x70580eA14d98a53fd59376dC7e959F4a6129bB9b, 290381000000);
        registerBounty(0x04f6bf3dc198becdda5fd7bb2cbfd4403b7bd522, 1161525000000);
        registerBounty(0x95d4914d4f08732a169367674a8be026c02c5b44, 2903813000000);
        registerBounty(0xF4919c366c3ad386f0A5Abe322d6cDe0238CeB28, 1161525000000);
        registerBounty(0x387c71683A05Cdf4Df2ccd861ad4eeD16F09F917, 2177858000000);
        registerBounty(0xD399E4f178D269DbdaD44948FdEE157Ca574E286, 871143000000);
        registerBounty(0x5889823CD24E11222ba370732218ffE1D9938108, 871143000000);
        registerBounty(0xb906b0641DD9578287c0B7Dbe33aFeC499F1841B, 1451906000000);
        registerBounty(0x1461b1E13ac15B849B8fa54DcFa93B3961992642, 1161525000000);
        registerBounty(0xe415638FC30b277EC7F466E746ABf2d406f821FF, 2177858000000);
        registerBounty(0xde7fb34d93f672a5d587dc0f8a416b13eed8547d, 871143000000);
        registerBounty(0xde7fb34d93f672a5d587dc0f8a416b13eed8547d, 1451906000000);
        registerBounty(0x76cc93e01a6d810a1c11bbc1054c37cb395f14c8, 1161525000000);
        registerBounty(0x76cc93e01a6d810a1c11bbc1054c37cb395f14c8, 1451906000000);
        registerBounty(0xBE762c447BA88E1B22C5A7248CBEF103032B8306, 871143000000);
        registerBounty(0xED2D17430709eddE66A3E67C2Dd761738fFD0fFd, 871143000000);
        registerBounty(0x472d1DdfFB017E9EBBB4B6d0d4e1296Af14bD703, 871143000000);
        registerBounty(0x76cc93e01a6d810a1c11bbc1054c37cb395f14c8, 1161525000000);
        registerBounty(0xfe4A4DA8DE5565e76392b79615375dDf6C504d11, 1451906000000);
        registerBounty(0xfe4A4DA8DE5565e76392b79615375dDf6C504d11, 871143000000);
        registerBounty(0xfe4A4DA8DE5565e76392b79615375dDf6C504d11, 871143000000);
        registerBounty(0xb967dDb883b417f620AaF09505fEBB77Ce0c2374, 1161525000000);
        registerBounty(0xED2D17430709eddE66A3E67C2Dd761738fFD0fFd, 871143000000);
        registerBounty(0xE633a1270A7086e1E4923835C0A5Cf06893D6a01, 871143000000);
        registerBounty(0x1eE06F228451C2d882b7afe6fD737989665BEc52, 1016334000000);
        registerBounty(0x36d091393dcEcd628C52ED4F7B80674107D66Bfa, 871143000000);
        registerBounty(0xb8Bb1F1423f66712Dbc9bC723411397480Acd32f, 871143000000);
        registerBounty(0x42FC0b269713e6F07974191a2c2303dB68d5f681, 871143000000);

        // Raise chunk added flag
        chunk2IsAdded = true;
    }

    /// @notice Add bounty chunk 3 / 3
    function addBountyChunk3() external onlyOwner {
        // Bounty chunk can be added only once
        require(!chunk3IsAdded);

        // Register bounties
        registerBounty(0x8BF0d9afCd2Bd5A779fBFa53b702C7B5A5EEBA05, 871143000000);
        registerBounty(0x8BF0d9afCd2Bd5A779fBFa53b702C7B5A5EEBA05, 871143000000);
        registerBounty(0x2b9840F282F167E8e8b0Ed8c2938DCaa1006c5D4, 2177858000000);
        registerBounty(0xbdD5645986F492954465b5E407f7528C0cF88fFA, 871143000000);
        registerBounty(0xbB1b7c3DA8920E63B2dc57193a79bbc237AAec7e, 871143000000);
        registerBounty(0x5c582DE6968264f1865C63DD72f0904bE8e3dA4a, 871143000000);
        registerBounty(0xbB1b7c3DA8920E63B2dc57193a79bbc237AAec7e, 871143000000);
        registerBounty(0xccb98e6af2b1dbe621fbac6b48e6e98811fe1243, 1161525000000);
        registerBounty(0xccb98e6af2b1dbe621fbac6b48e6e98811fe1243, 1451906000000);
        registerBounty(0x4C2C20542d75E08328d21f0c7365823d2752e07c, 1161525000000);
        registerBounty(0x944f0d58ec256528116D622330B93F8Af80c8c35, 1161525000000);
        registerBounty(0x387c71683A05Cdf4Df2ccd861ad4eeD16F09F917, 2177858000000);
        registerBounty(0x6eB0B9EbC4eD419F5e7330620d647E4113Ae29EF, 1161525000000);
        registerBounty(0x6eB0B9EbC4eD419F5e7330620d647E4113Ae29EF, 1161525000000);
        registerBounty(0x6eB0B9EbC4eD419F5e7330620d647E4113Ae29EF, 1161525000000);
        registerBounty(0x6eB0B9EbC4eD419F5e7330620d647E4113Ae29EF, 1451906000000);
        registerBounty(0x9d13dF46A009e1c6195908043166cf86d885ED84, 871143000000);
        registerBounty(0x9d13dF46A009e1c6195908043166cf86d885ED84, 871143000000);
        registerBounty(0x4A116f5605159Db8F958F19e57712EFe3A29F99b, 871143000000);
        registerBounty(0x4A116f5605159Db8F958F19e57712EFe3A29F99b, 871143000000);
        registerBounty(0x4897447ad5b75B30ff3D988628a6AE12b71ED15B, 1161525000000);
        registerBounty(0xb4F9F2bA99b6BE2759ED7461058e80c2297734eA, 1161525000000);
        registerBounty(0xb4F9F2bA99b6BE2759ED7461058e80c2297734eA, 1161525000000);
        registerBounty(0x4897447ad5b75B30ff3D988628a6AE12b71ED15B, 871143000000);
        registerBounty(0xD76fE7347bEB14C9BD0D5A50bf3B69A4e27CFa3b, 871143000000);
        registerBounty(0xD76fE7347bEB14C9BD0D5A50bf3B69A4e27CFa3b, 871143000000);
        registerBounty(0x2a06C794A2B2D7F86094765C258f1a1B06CA1813, 1161525000000);
        registerBounty(0x7375C73586881AcC913015E56cccB4c9D63AAf45, 871143000000);
        registerBounty(0x7375C73586881AcC913015E56cccB4c9D63AAf45, 871143000000);
        registerBounty(0x7375C73586881AcC913015E56cccB4c9D63AAf45, 871143000000);
        registerBounty(0x469579CaC0F8C4e62195b25449B885e5e048D2dC, 871143000000);
        registerBounty(0x469579CaC0F8C4e62195b25449B885e5e048D2dC, 871143000000);
        registerBounty(0x469579CaC0F8C4e62195b25449B885e5e048D2dC, 871143000000);
        registerBounty(0x43D58a3D64062e4E2cF6aD285c7FE3a8B25741cC, 1161525000000);
        registerBounty(0x43D58a3D64062e4E2cF6aD285c7FE3a8B25741cC, 1161525000000);
        registerBounty(0x43D58a3D64062e4E2cF6aD285c7FE3a8B25741cC, 1161525000000);

        // Raise chunk added flag
        chunk3IsAdded = true;
    }

    /// @notice Power-up current bounty contract
    function powerUpContract() external onlyOwner {
        // Contract can be powered up only once
        require(!contractPoweredUp);

        // Get balance of this contract account in Parsec credits
        uint256 currentBalance = parsecToken.balanceOf(this);

        // Check if contract balance is equal or greated than `REQUIRED_CREDITS_AMOUNT`
        require(currentBalance >= REQUIRED_CREDITS_AMOUNT);

        // Check if bounty chunk 1 / 3 is added
        require(chunk1IsAdded);

        // Check if bounty chunk 2 / 3 is added
        require(chunk2IsAdded);

        // Check if bounty chunk 3 / 3 is added
        require(chunk3IsAdded);

        // Raise contract powered-up flag
        contractPoweredUp = true;
    }

    /// @notice The owner can withdraw unclaimed Parsec credits when claim period is over
    function ownerWithdrawUnclaimedCredits() external onlyOwner {
        // The owner cannot withdraw unclaimed Parsec credits until claim period is over
        require(now >= CLAIM_END_DATE);

        // Get balance of this contract account in Parsec credits
        uint256 currentBalance = parsecToken.balanceOf(this);

        // The owner cannot withdraw unclaimed Parsec credits if there are none
        require(currentBalance > 0);

        // Transfer unclaimed Parsec credits back to this contract owner
        parsecToken.transfer(owner, currentBalance);
    }

    /// @notice Participant can claim bounty in Parsec credits during claim period only
    function participantClaimCredits() external {
        // Check if claim period is active
        require(now >= CLAIM_START_DATE);
        require(now < CLAIM_END_DATE);

        // Get bounty amount for current participant
        uint256 bountyAmount = bountyOf[msg.sender];

        // There should be something to claim
        require(bountyAmount > 0);

        // Participant's bounty in Parsec credits is set to zero
        bountyOf[msg.sender] = 0;

        // Update amount of Parsec credits actually claimed
        actuallyClaimedAmount = actuallyClaimedAmount.add(bountyAmount);

        // Log bounty claim
        LogBountyClaim(msg.sender, bountyAmount, now);

        // Transfer Parsec credits to participant
        parsecToken.transfer(msg.sender, bountyAmount);
    }

    /// @notice Register bounty
    function registerBounty(address participant, uint256 value) private {
        // Participant's bounty is increased by `value`
        bountyOf[participant] = bountyOf[participant].add(value);

        // Keep track of the total amount of Parsec credits to claim
        totalAmountToClaim = totalAmountToClaim.add(value);
    }
}