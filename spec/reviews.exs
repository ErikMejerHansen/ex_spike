# Requirements checked by hand, by requirement ID.
#
# Use this for requirements that tests can't fully cover. Say what was
# checked and how. A requirement whose tests pass doesn't need a review,
# but a review can add what the tests miss.
#
# Update or remove a review when its requirement changes.
%{
  "ARCH-5" =>
    "Framing is byte-identical to LEGO's Python reference (examples/python/cobs.py) " <>
      "on 2000 random inputs. Message layouts follow docs/source/messages.rst; strings " <>
      "are sent unpadded with a null terminator, as in examples/python/messages.py.",
  "DOC-1" =>
    "README plus module and function docs with runnable examples, reviewed for " <>
      "length and clarity.",
  "TEST-1" =>
    "Tests are grouped in describe \"Given ...\" blocks with " <>
      "test \"when ..., then ...\" names; doctests double as examples."
}
