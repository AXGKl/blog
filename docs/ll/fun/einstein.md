# A Famous Riddle & Amazing Prolog

[2021-10-16 00;44] 

The Einstein puzzle (also called zebra puzzle) is the most famous logic puzzle / logical ever. Albert Einstein [1879-1955] is sometimes mentioned as the author. He allegedly stated that only 2% of the population was able to solve it. It can actually be solved by logical conclusions – even if that's not easy. Have fun!


## The Riddle: 5 Houses...

Five houses stand next to each other. They are home to people of five different nationalities who drink five different drinks, smoke five different brands of cigarettes and have five different pets.‎

- The Englishman lives in the red house.
- The Spaniard has a dog.
- The Ukrainian likes to drink tea.
- The green house is (directly) to the left of the White House.
- Coffee is drunk in the green house.
- The person who smokes Old-Gold has a snail.
- The occupant of the middle house drinks milk.
- The occupant of the yellow house smokes Kools.
- The Norwegian lives in the first house.
- The Chesterfields smoker lives next to the person with the fox.
- The man with the horse lives next to the person who smokes Kools.
- The Lucky Strike smoker drinks orange juice.
- The Norwegian lives next to the blue house.
- The Japanese smoke Parliaments.
- The Chesterfields smoker has a neighbor who drinks water.
- Find out who owns the zebra!

## In Software

As good software engineers we clearly rather hack a program than to even think about solving it
using brains and stuff - even if it takes double the time :-/

### The Problem

Problem was obvious after the first attempt: Brute forcing it is too much, at least in python: There are 25 billion combinations to consider.

5 categories with 5 values each means: 120 (5 * 4 * 3 * 2 * 1) combinations per category, i.e. 120 ** 5 solution candidates, passing into the 15 constraints checker.

### Simple and Hard Constraints:

So we had to group the information into 2 classes, 'easy' ones which directly lead to fast filtering of candidates.  
And only passing the filtered ones into the validation for the hard ones, involving neighbor-based constraints.

Here is my program - not exactly elegant but with good intentions. Sorry for the German constraints,
took them from elsewhere:

```python
# fmt:off
from pprint import pprint
# Categories (all indizes from 0):
zigs, nation, drink, animal, color = range(5)
# Attributes:
oldgold , parliaments , luckies , chester , kools  = range(5)
england , spain       , ukraine , norway  , japan  = range(5)
tea     , coffee      , water   , milk    , orange = range(5)
dog     , horse       , fox     , zebra   , snail  = range(5)
red     , green       , white   , yellow  , blue   = range(5)

# A 5x5x5x5x5 matrix:
r = range(5); M = [[a, b, c, d, e] for a in r for b in r for c in r for d in r for e in r]

# fmt:on
# any attrib just once:
S = {0, 1, 2, 3, 4}
# All 120 combis of an attr (5 * 4 * 3 * 2 * 1) = 120:
Combis = [i for i in M if set(i) == S]


def house(H, key, val):
    """return house and position of a certain key value pair"""
    for p in range(5):
        if H[p][key] == val:
            return H[p], p


def validate(H, house=house):
    """Checking the given constraints.
    H a valid config.
    Edit: The easy ones already done via filters, commented out. Too slow otherwise.
    """
    # Der Engländer lebt im roten Haus.
    # assert house(H, nati, england)[0][colo] == red
    # Der Ukrainer trinkt gern Tee.
    # assert house(H, nati, ukraine)[0][drnk] == tea
    # Der Spanier hat einen Hund.
    assert house(H, nation, spain)[0][animal] == dog, 1
    # Das grüne Haus ist (direkt) links vom weißen Haus.
    p = house(H, color, green)[1]
    assert p < 4 and H[p + 1][color] == white, 2
    # Im grünen Haus wird Kaffee getrunken.
    # assert house(H, colo, green)[0][drnk] == coffee
    # Die Person, die Old-Gold raucht, hat eine Schnecke.
    assert house(H, zigs, oldgold)[0][animal] == snail, 3
    # Der Bewohner des mittleren Hauses trinkt Milch.
    # assert H[2][drnk] == milk
    # Der Bewohner des gelben Hauses raucht Kools.
    # assert house(H, colo, yellow)[0][zigs] == kools
    # Der Norweger wohnt im ersten Haus.
    # assert H[0][nati] == norway
    # Der Chesterfields-Raucher wohnt neben der Person mit der Fuchs.
    p = house(H, zigs, chester)[1]
    assert (p > 0 and H[p - 1][animal] == fox) or (p < 4 and H[p + 1][animal] == fox), 4
    # Der Lucky-Strike-Raucher trinkt Orangensaft.
    # assert house(H, zigs, luckies)[0][drnk] == orange
    # Der Norweger wohnt neben dem blauen Haus.
    # p = house(H, nati, norway)[1]
    # assert (p > 0 and H[p - 1][colo] == blue) or (p < 4 and H[p + 1][colo] == blue)
    # Der Japaner raucht Parliaments.
    # h = house(H, nati, japan)[0]
    # assert h[zigs] == parliaments
    # Der Chesterfields-Raucher hat einen Nachbarn, der Wasser trinkt.
    p = house(H, zigs, chester)[1]
    assert (p > 0 and H[p - 1][drink] == water) or (
        p < 4 and H[p + 1][drink] == water
    ), 6
    # Der Mann mit dem Pferd lebt neben der Person, die Kools raucht.
    p = house(H, animal, horse)[1]
    assert (p > 0 and H[p - 1][zigs] == kools) or (p < 4 and H[p + 1][zigs] == kools), 7


def main():
    for nation in Combis:
        if not nation[0] == norway:
            continue
        for cig in Combis:
            if not cig[nation.index(japan)] == parliaments:
                continue
            for drink in Combis:
                # mittleres haus = milk
                if not drink[2] == milk:
                    continue
                if not drink[nation.index(ukraine)] == tea:
                    continue
                # Der Lucky-Strike-Raucher trinkt Orangensaft.
                if not drink[cig.index(luckies)] == orange:
                    continue
                for color in Combis:
                    # norweger (at 0) neben blauem haus:
                    if not color[1] == blue:
                        continue
                    # gelbes house: kools
                    if not cig[color.index(yellow)] == kools:
                        continue
                    # englaender in rotem:
                    if not color[nation.index(england)] == red:
                        continue
                    # Im grünen Haus wird Kaffee getrunken.
                    if not drink[color.index(green)] == coffee:
                        continue
                    for animal in Combis:
                        candidate = [
                            [cig[i], nation[i], drink[i], animal[i], color[i],]
                            for i in range(5)
                        ]
                        try:
                            validate(candidate)
                            return candidate
                        except AssertionError:
                            pass


if __name__ == '__main__':
    h = main()
    print('Attribs (all indices from 0):')
    c = open(__file__).read().split('\n', 3)[3].split('# A ', 1)[0]
    print(c.replace('= range(5)', ''))
    print('Solution:')
    pprint(h)
    print('Zebra at: ', house(h, animal, zebra))
```

Runtime now is pretty fast:

```bash
~/Dow/pypy3.8-v7.3.6-linux64 ❯ time bin/pypy3 einstein.py
Attribs (all indices from 0):
zigs, nation, drink, animal, color
# Attributes:
oldgold , parliaments , luckies , chester , kools
england , spain       , ukraine , norway  , japan
tea     , coffee      , water   , milk    , orange
dog     , horse       , fox     , zebra   , snail
red     , green       , white   , yellow  , blue


Solution:
[[4, 3, 2, 2, 3],
 [3, 2, 0, 1, 4],
 [0, 0, 3, 4, 0],
 [1, 4, 1, 3, 1],
 [2, 1, 4, 0, 2]]
Zebra at:  ([1, 4, 1, 3, 1], 3)
bin/pypy3 einstein.py  0.13s user 0.02s system 99% cpu 0.156 total
```

In CPython: 0.58s, matching pypy's claimed 4 times speed up on average.

> => The Japanese (nation=4) has the zebra, in the 4.th house (idx=3).


## Fascinating Prolog

The riddle actually is a fantastic candidate for declarative programming. 

Look at this implementation, in admiration:

```prolog
% A steht links neben B
leftof(A, B, [A, B|_]).
leftof(A, B, [_|R]) :- leftof(A, B, R).

% A steht neben B
nextto(A, B, H) :- leftof(A, B, H); leftof(B, A, H).

% A ist das erste Haus
first(A, [A|_]).

% A steht in der Mitte
inthemiddle(A, [_, _, A, _, _]).

% Das Raetsel
einstein :-
  % 5 Haeuser stehen nebeneinander.
  H = [_, _, _, _, _],
  % Der Englaender lebt im roten Haus.
  member([englaender, rot, _, _, _], H),
  % Der Spanier hat einen Hund.
  member([spanier, _, hund, _, _], H),
  % Der Ukrainer trinkt gern Tee.
  member([ukrainer, _, _, tee, _], H),
  % Das gruene Haus ist (direkt) links vom weissen Haus.
  leftof([_, gruen, _, _, _], [_, weiss, _, _, _], H),
  % Im gruenen Haus wird Kaffee getrunken.
  member([_, gruen, _, kaffee, _], H),
  % Die Person, die Old-Gold raucht, hat eine Schnecke.
  member([_, _, schnecke, _, oldgold], H),
  % Der Bewohner des mittleren Hauses trinkt Milch.
  inthemiddle([_, _, _, milch, _], H),
  % Der Bewohner des gelben Hauses raucht Kools.
  member([_, gelb, _, _, kools], H),
  % Der Norweger wohnt im ersten Haus.
  first([norweger, _, _, _, _], H),
  % Der Chesterfields-Raucher wohnt neben der Person mit
  % der Fuchs.
  nextto([_, _, _, _, chesterfields], [_, _, fuchs, _, _], H),
  % Der Mann mit dem Pferd lebt neben der Person, die
  % Kools raucht.
  nextto([_, _, pferd, _, _], [_, _, _, _, kools], H),
  % Der Lucky-Strike-Raucher trinkt Orangensaft.
  member([_, _, _, orangensaft, luckystrike], H),
  % Der Norweger wohnt neben dem blauen Haus.
  nextto([norweger, _, _, _, _], [_, blau, _, _, _], H),
  % Der Japaner raucht Parliaments.
  member([japaner, _, _, _, parliaments], H),
  % Der Chesterfields-Raucher hat einen Nachbarn, der Wasser
  % trinkt.
  nextto([_, _, _, _, chesterfields], [_, _, _, wasser, _], H),
  % Wem gehoert das Zebra?
  member([N, _, zebra, _, _], H),
  write('Der '),
  write(N),
  write('\n'),
  write(H),
  write(' haelt das Zebra.'),
  !.
```

That's it. Amazing!



