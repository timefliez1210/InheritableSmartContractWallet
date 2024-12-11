[High] No Access Controll for inherit() to set owner to msg.sender if only one beneficiary was pushed. The function should either have access controll or better set the new owner to index 0 of the beneficiaries array.

[High] Constructor fails to initialize deadline. Contract could be inherited with funds right away.

[High] No address(0) check is performed on the withdrawInheritedFunds which in this case would be critical since we do not really remove entries out of the array with remove(index) (connected to Medium 1, depending on recommended fix, this could be 2 tags)

[High] A malicious beneficiary could reenter the withdrawInheritedFnds function

[High] There is no way to unwind DeFi positions from contractInteractions() the original owner might have done in case there is more than one beneficiary (inheritance scenario)

[High] nonReentrant modifier assings ```if(tload(1))``` which is incorrect and renders the modifier useless since it will always return true. Transient storage key has to be checked as ```if(tload(0))```

[High] buyOutEstateNFT() uses the wrong divisor while sending the tokens to the recipients

[Medium] correlated to [High] 3. removeBeneficiary does not really remove the index entry leading to remaining funds from withdrawInheritedFunds, if we would perform an address(0) check after all, since the divisor is greater than it should be. To be considered medium in this case since it violates the ease-of-use premise of this contract (we do not expect the beneficiaries to know much about crypto etc.). [Medium] 1 and [High] 3 can be fixed together by removing indices with pop() looping over the array to move an entry to the end.

[Medium] The contract lacks functionality to actually receive ether

