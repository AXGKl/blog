#!/usr/bin/env python
"""
# A Solver for the Android game [unblockme][1]

## Config

Supply the board's initial state like this:

    - Every piece (block) gets a unique number, starting from 1, counting up
    - The red piece must have nr 1
    - Empty cells get 0

### Exmple:

Board 605 would be:

```python

    board_605 = [
        [2 , 3  , 4  , 4  , 4  , 0] ,
        [2 , 3  , 0  , 5  , 6  , 0] ,
        [2 , 1  , 1  , 5  , 6  , 0] ,
        [7 , 7  , 8  , 0  , 6  , 0] ,
        [0 , 0  , 8  , 9  , 9  , 0] ,
        [0 , 10 , 10 , 11 , 11 , 0] ,
    ]

```

## Solving Method: Brute Force, Breadth First. Only Single Cell Moves

!!! important

    That method will find the a solution **close** (due to the single cell moves) to the optimum.


[1]: https://play.google.com/store/apps/details?id=com.kiragames.unblockmefree
"""


import sys
from dataclasses import dataclass  # for nice print outs of pieces
from time import time

# fmt:off
# ------------------------------------------------------------------------------- config
# piece nr 1 must be the one to free (the red one):
board_simple = [
    [4, 0, 2, 0, 3, 3],
    [4, 0, 2, 0, 0, 5],
    [1, 1, 0, 0, 0, 5],
    [0, 0, 0, 0, 0, 5],
    [0, 0, 0, 0, 0, 0],
    [6, 6, 6, 0, 0, 0],
]

board_605 = [
    [2 , 3  , 4  , 4  , 4  , 0] ,
    [2 , 3  , 0  , 5  , 6  , 0] ,
    [2 , 1  , 1  , 5  , 6  , 0] ,
    [7 , 7  , 8  , 0  , 6  , 0] ,
    [0 , 0  , 8  , 9  , 9  , 0] ,
    [0 , 10 , 10 , 11 , 11 , 0] ,
]

# different indexing:
board_6052 = [
    [11 , 3  , 4  , 4  , 4  , 0] ,
    [11 , 3  , 0  , 5  , 6  , 0] ,
    [11 , 1  , 1  , 5  , 6  , 0] ,
    [7 , 7  , 8  , 0  , 6  , 0] ,
    [0 , 0  , 8  , 9  , 9  , 0] ,
    [0 , 10 , 10 , 2 , 2 , 0] ,
]


board_638 = [
    [0  , 3  , 4  , 5 , 5 , 5] ,
    [2  , 3  , 4  , 6 , 0 , 0] ,
    [2  , 1  , 1  , 6 , 0 , 0] ,
    [2  , 7  , 7  , 8 , 8 , 9] ,
    [0  , 0  , 10 , 0 , 0 , 9] ,
    [11 , 11 , 10 , 0 , 0 , 9] ,
]

board_3 = [
    [0  , 2  , 3  , 3 , 6 , 7] ,
    [0  , 2  , 4  , 5 , 6 , 7] ,
    [1  , 1  , 4  , 5 , 6 , 8] ,
    [0  , 9  , 9  ,10 , 0 , 8] ,
    [0  , 0  , 0  ,10 , 0 , 0] ,
    [0  , 11 , 11 ,12 ,12 , 0] ,
]

board_impossible = [
    [0  , 3  , 4  , 5 , 5 , 5] ,
    [2  , 3  , 4  , 6 , 0 , 0] ,
    [2  , 1  , 1  , 6 , 12,12] ,
    [2  , 7  , 7  , 8 , 8 , 9] ,
    [0  , 0  , 10 , 0 , 0 , 9] ,
    [11 , 11 , 10 , 0 , 0 , 9] ,
]

# fmt:on

board = board_605
# --------------------------------------------------------------------------- end config

t0 = time()

# printing the board, with bg colors:
# ansi colors:
_ = {0: 244, 7: 59, 9: 58, -1: 56}
bgs = {k: '\x1b[48;5;%sm%%s' % _.get(k, k) for k in range(-1, 20)}


def print_board(b=None, p=None):
    b = b or board
    print()
    for r in b:
        for c in r:

            bg = bgs.get(c, bgs[2])
            if p:
                if p == c:
                    bg = bgs[-1]
            else:
                if moves and c == abs(moves[-1]):
                    bg = bgs[-1]

            if c == 0:
                c = ' '
            elif c > 9:  # a, b, c, ...:
                c = chr(87 + c)
            # c = fg % c if fg else c
            print(bg % c, end='')
        print('\x1b[0m')
    print()


pb = print_board  # debug alias
horiz, vert = 'h', 'v'


def board_by_row_and_col(r, c):
    """handling out of bounds w/o exceptions"""
    if r < 0 or c < 0:
        return -1
    try:
        return board[r][c]
    except:
        return -1


# (Pdb) pp pieces
# {1: Piece(nr=1, row=2, col=0, len=2, dir='h'),
#  2: Piece(nr=2, row=0, col=2, len=2, dir='v'),
# (...)
#  6: Piece(nr=6, row=5, col=0, len=3, dir='h')}
pieces = {}

moves = []

states = set()


@dataclass
class Piece:
    nr: int = 0
    row: int = 0
    col: int = 0
    len: int = 0
    dir: int = vert

    def setup(self):
        """Determine vertical or horizontal and set the length"""
        r, c, n = self.row, self.col, self.nr
        self.dir = vert if (r < len(board) - 1 and board[r + 1][c] == n) else horiz
        self.set_len()
        return self

    def set_len(self):
        """How long is this piece"""
        r, c, n = self.row, self.col, self.nr
        l = 0
        if self.dir == horiz:
            while board_by_row_and_col(r, c + l) == n:
                l += 1
                self.len = l

        elif self.dir == vert:
            while board_by_row_and_col(r + l, c) == n:
                l += 1
                self.len = l

    def go_left_if_new_state(self):
        """left or up"""
        if self.dir == vert:
            return self.move(-1, 0)
        else:
            return self.move(0, -1)

    def go_right_if_new_state(self):
        """right or down"""
        if self.dir == vert:
            return self.move(1, 0)
        else:
            return self.move(0, 1)

    def move(self, row_offs, col_offs):
        # CAN we move?
        or_, oc = self.row, self.col
        nr, nc = self.row + row_offs, self.col + col_offs
        rl, cl = 0, 0
        if row_offs == 1:
            rl = self.len - 1
        elif col_offs == 1:
            cl = self.len - 1
        if board_by_row_and_col(nr + rl, nc + cl) != 0:
            return
        # Try do the move - then check for having new state:
        self.row, self.col = nr, nc
        if not have_new_state():
            self.row, self.col = or_, oc
            return

        # are we right/down (-> 1) or left/up (-> -1):
        is_right_or_down = row_offs + col_offs

        # register the move (our nr with minus if it's left/up, else +):
        moves.append(self.nr * is_right_or_down)
        l = ': ' if len(moves) < 10 else ': ...'
        # print('Move', len(moves), l, ', '.join([str(i) for i in moves[-10:]]))

        # set the board accordingly:
        if is_right_or_down == 1:
            # move right or down:
            board[or_][oc] = 0
            board[nr + rl][nc + cl] = self.nr
        else:
            # move left or up:
            board[self.row][self.col] = self.nr
            if self.dir == horiz:
                board[self.row][self.col + self.len] = 0
            else:
                board[self.row + self.len][self.col] = 0
        return True


def register_pieces():
    def top_left_piece_position(p):
        for r, row in zip(board, range(len(board))):
            for c, col in zip(r, range(len(r))):
                if c == p:
                    return row, col

    p = 0
    while True:
        p += 1
        tl = top_left_piece_position(p)
        if not tl:
            break
        pieces[p] = Piece(nr=p, row=tl[0], col=tl[1]).setup()


def calc_state():
    """get a unique id per board(=pieces) state"""
    s = ''
    for nr in range(1, len(pieces) + 1):
        p = pieces[nr]
        row, col = p.row, p.col
        s += f'{nr}{row}{col}:'
        # if nr == 5 and row == 2: breakpoint()  # FIXME BREAKPOINT
    return s


def have_new_state():
    s = calc_state()
    if not s in states:
        states.add(s)
        return True


def check_solved(prev):
    """Is all right of piece nr 1 a zero?"""
    p = pieces[1]
    row, col, ln = p.row, p.col, p.len
    for c in board[row][col + ln :]:
        if c != 0:
            return False
    lmoves = len(tree)
    lstates = len(states)
    sec = round(time() - t0, 2)
    print(
        f'Solved in {lmoves} single cell moves (producing {lstates} States). Took {sec}sec.'
    )
    print_solution(prev, sec)
    sys.exit(0)
    return True


clone_state = lambda s: [[k for k in r] for r in s]

tree = []

# :docs:bfs1print
def print_solution(prev, sec):
    move_nr = len(tree) + 1
    old_piece = -1
    nr_moves = len(tree)
    while tree:
        move_nr -= 1
        moves = tree.pop()
        try:
            for move in moves:
                ns = move['next_states']
                for state in ns:
                    if state['board'] == prev:
                        piece = state['nr']
                        if piece == old_piece:
                            # a piece is moved over > 1 cells, this counts as ONE move:
                            # adding 1 will result in us reporting one move less then:
                            move_nr += 1
                        print('move ', move_nr, piece)
                        print_board(prev, piece)
                        prev = move['prev']
                        old_piece = piece
                        raise
            print('No solution found')
            sys.exit(1)
        except:
            pass
    lmoves = nr_moves - move_nr
    lstates = len(states)
    print(f'Solved in {lmoves} moves (producing {lstates} States). Took {sec}sec.')


# :docs:bfs1print

# :docs:bfs1_mainloop
def all_states_one_move_deeper():
    global board
    last_states = tree[-1]
    print('next move: ', len(tree))
    print('breadth is: ', len(last_states))
    next_states = []
    for s in last_states:
        ns = s['next_states']
        for state in ns:
            state = state['board']
            possbl_mov = []
            for nr in range(1, len(pieces) + 1):
                board = clone_state(state)
                register_pieces()
                p = pieces[nr]
                r = p.go_left_if_new_state()
                if r:
                    possbl_mov.append({'board': clone_state(board), 'nr': nr})
                    check_solved(state)
                board = clone_state(state)
                register_pieces()
                p = pieces[nr]
                r = p.go_right_if_new_state()
                if r:
                    possbl_mov.append({'board': clone_state(board), 'nr': nr})
                    check_solved(state)
            if possbl_mov:
                next_states.append({'next_states': possbl_mov, 'prev': state})
    if next_states:
        tree.append(next_states)
    else:
        print('no solution')
        sys.exit(1)


def main():
    print('Start State:')
    print_board()
    register_pieces()
    tree.append([{'prev': None, 'next_states': [{'board': board, 'nr': 0}]}])
    while True:
        all_states_one_move_deeper()


# :docs:bfs1_mainloop

if __name__ == '__main__':
    main()
