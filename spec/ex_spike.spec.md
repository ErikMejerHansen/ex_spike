# EARS
## Syntax: While <optional pre-condition>, when <optional trigger>, the <system name> shall <system response>
## Examples
Ubiquitous requirements
Ubiquitous requirements are always active (so there is no EARS keyword)

The <system name> shall <system response>

Example: The mobile phone shall have a mass of less than XX grams.

State driven requirements
State driven requirements are active as long as the specified state remains true and are denoted by the keyword While.

While <precondition(s)>, the <system name> shall <system response>

Example: While there is no card in the ATM, the ATM shall display “insert card to begin”.

Event driven requirements
Event driven requirements specify how a system must respond when a triggering event occurs and are denoted by the keyword When.

When <trigger>, the <system name> shall <system response>

Example: When “mute” is selected, the laptop shall suppress all audio output.

Optional feature requirements
Optional feature requirements apply in products or systems that include the specified feature and are denoted by the keyword Where.

Where <feature is included>, the <system name> shall <system response>

Example: Where the car has a sunroof, the car shall have a sunroof control panel on the driver door.

Unwanted behaviour requirements
Unwanted behaviour requirements are used to specify the required system response to undesired situations and are denoted by the keywords If and Then.

If <trigger>, then the <system name> shall <system response>

Example: If an invalid credit card number is entered, then the website shall display “please re-enter credit card details”.

Complex requirements
The simple building blocks of the EARS patterns described above can be combined to specify requirements for richer system behaviour. Requirements that include more than one EARS keyword are called Complex requirements.

While <precondition(s)>, When <trigger>, the <system name> shall <system response>

# Requirement IDs

Every requirement is a list item starting with a unique ID, like
`- [ARCH-4] The ExSPIKE shall ...`. Tests and reviews refer
to requirements by ID, so:

- To add a requirement, give it the next free ID in its section.
- To reword a requirement without changing its meaning, keep its ID.
- To change what a requirement means, give it a new ID. Its old tests
  and reviews then no longer count, until they are updated.
- To remove a requirement, delete it. Never reuse its ID.

Run `mix spec` to see which requirements are implemented, in
[STATUS.md](STATUS.md).

# Spec

## Architecture
- [ARCH-1] The hex package name for this SPIKE Protocol/Message Handler shall be ex_spike
- [ARCH-2] The top level namespace for this project shall be ExSPIKE

- [ARCH-3] The ExSPIKE shall be implemented in Elixir
- [ARCH-4] The ExSPIKE shall be completely stateless
- [ARCH-5] The ExSPIKE shall implement the message encoding/decoding described on https://lego.github.io/spike-prime-docs/
- [ARCH-6] The ExSPIKE shall allow creation of the messages described on https://lego.github.io/spike-prime-docs/ via easy to use functions
- [ARCH-7] The ExSPIKE shall allow creation of the messages described on https://lego.github.io/spike-prime-docs/ via bitstrings
- [ARCH-8] The ExSPIKE shall allow encoding and decoding of messages

## Documentation
- [DOC-1] The ExSPIKE shall have concise and easy to read documentation
- [DOC-2] The ExSPIKE shall make it clear that there is no affiliation with The LEGO Group

## Testing
- [TEST-1] The ExSPIKE shall have easy to read tests in a BDD style
