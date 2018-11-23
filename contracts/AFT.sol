pragma solidity ^0.4.6;

contract Owned {

    // The address of the account that is the current owner 
    address public owner;


    constructor() public {
       owner = msg.sender;
    }
    /**
     * Access is restricted to the current owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    /**
     * Transfer ownership to `_newOwner`
     *
     * @param _newOwner The address of the account that will become the new owner 
     */
    function transferOwnership(address _newOwner) onlyOwner {
        require(_newOwner != address(0), "cannot transfer ownership to address zero");
        owner = _newOwner;
    }
}

contract Pausable is Owned {
  event Pause();
  event Unpause();
  event PauserChanged(address newAddress);


  address public pauser;

  bool public paused = false;

  constructor() public {
    pauser = msg.sender;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused, "Paused");
    _;
  }

  /**
   * @dev throws if called by any account other than the pauser
   */
  modifier onlyPauser() {
    require(msg.sender == pauser,"onlyPauser can do this");
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyPauser public {
    require(!paused, "already paused");
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyPauser public {
    require(paused, "already unpaused");
    paused = false;
    emit Unpause();
  }

  /**
   * @dev update the pauser role
   */
  function updatePauser(address _newPauser) onlyOwner public {
    require(_newPauser != address(0),"cannot transfer pauser to address zero");
    pauser = _newPauser;
    emit PauserChanged(pauser);
  }

}

library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function minimum( uint a, uint b) internal returns ( uint result) {
    if ( a <= b ) {
      result = a;
    }
    else {
      result = b;
    }
  }

}

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address  _from, address  _to, uint256 _value);
    event Approval(address  _owner, address  _spender, uint256 _value);
}

/**
 * Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
 *
 * Modified version of https://github.com/ConsenSys/Tokens that implements the 
 * original Token contract, an abstract contract for the full ERC 20 Token standard
 */
contract StandardToken is Token,Pausable{

    using SafeMath for uint256;

    // Token starts if the locked state restricting transfers
    bool public locked;

    // DCORP token balances
    mapping (address => uint256) balances;

    // DCORP token allowances
    mapping (address => mapping (address => uint256)) allowed;
    

    /** 
     * Get balance of `_owner` 
     * 
     * @param _owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }


    /** 
     * Send `_value` token to `_to` from `msg.sender`
     * 
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _value) whenNotPaused returns (bool success) {

        require(_to != address(0), "cannot transfer to address zero");
        require(_value <= balances[msg.sender], "insufficient funds");

        // Transfer tokens
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        // Notify listners
        Transfer(msg.sender, _to, _value);
        return true;
    }


    /** 
     * Send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * 
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused returns (bool success) {

        require(_to != address(0), "cannot transfer to address zero");
        require(_value <= balances[_from], "insufficient funds");
        require(_value <= allowed[_from][msg.sender], "insufficient allowance");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }


    /** 
     * `msg.sender` approves `_spender` to spend `_value` tokens
     * 
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) whenNotPaused returns (bool success) {
        require(_spender != address(0), "spender address zero");
        require(_value >= 0, "value need > 0");

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    /** 
     * Get the amount of remaining tokens that `_spender` is allowed to spend from `_owner`
     * 
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender)  constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}


/**
 * @title HUSDToken
 *
 * Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20 with the addition 
 * of ownership, a lock and issuing.
 *
 * #created 05/03/2017
 * #author Frank Bonnet
 */
contract AFTToken is Owned, StandardToken {

    // Ethereum token standaard
    string public standard = "AFTToken 0.1";

    // Full name
    string public name = "ALabsFirstToken";        
    
    // Symbol
    string public symbol = "AFT";

    // No decimal points
    uint8 public decimals = 8;

    uint256 public  MAX_SUPPLY_OF_TOKEN = 1300000000 * 10 ** decimals;


    /**
     * Starts with a total supply of zero and the creator starts with 
     * zero tokens (just like everyone else)
     */
    constructor() public {  
        balances[msg.sender] = MAX_SUPPLY_OF_TOKEN;
        totalSupply = MAX_SUPPLY_OF_TOKEN;
    }

    function getSymbol() public constant returns(string){
        return symbol;
    }

    /**
     * Issues `_value` new tokens to `_recipient` (_value < 0 guarantees that tokens are never removed)
     *
     * @param _recipient The address to which the tokens will be issued
     * @param _value The amount of new tokens to issue
     * @return Whether the approval was successful or not
     */
    function mint(address _recipient, uint256 _value) onlyOwner returns (bool success) {

        require(_recipient != address(0), "cannot mint to address zero");
        require(_value != 0, "can not mint zero Token");

        // Create tokens
        balances[_recipient] += _value;
        totalSupply += _value;

        // Notify listners
        Transfer(0, owner, _value);
        Transfer(owner, _recipient, _value);

        return true;
    }

    function burn(uint256 _amount) whenNotPaused onlyOwner public {
        uint256 balance = balances[msg.sender];
        require(_amount > 0);
        require(balance >= _amount);

        totalSupply = totalSupply.sub(_amount);
        balances[msg.sender] = balance.sub(_amount);
        Transfer(msg.sender, address(0), _amount);
    }


    /**
     * Prevents accidental sending of ether
     */
    function () {
        throw;
    }
}