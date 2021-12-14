#!/usr/bin/env python
"""
# A Solver for the game klotski

https://www.y8.com/games/klotski

## Config

Supply the board's initial state like this:

    - Every piece (block) gets a unique number, starting from 1, counting up
    - The big piece to free must have nr 1
    - Empty cells get 0

"""


import sys
from dataclasses import dataclass  # for nice print outs of pieces
from time import time

# fmt:off
# ------------------------------------------------------------------------------- config
# piece nr 1 must be the one to free (the red one):
board_1 = [
    [1, 1, 2, 0],
    [1, 1, 3, 0],
    [4, 8, 9,11],
    [5, 8,10,11],
    [6, 6, 7, 7],
]

board_2 = [
    [2, 1, 1, 3],
    [2, 1, 1, 3],
    [4, 6, 6, 9],
    [4, 7, 8, 9],
    [5, 0, 0,10],
]

board_hard = [
    [2 , 1, 1, 3, 4, 4],
    [2 , 1, 1, 5, 6, 6],
    [7 , 8,10,11,12,13],
    [7 , 9,10,14,15,16],
    [17,17,18,19,20,16],
    [24,24,25,19,21,22],
    [24,24, 0, 0,23,22],
    ]

# fmt:on

# piece 1 here and we are done:
solved_row, solved_col = 3, 1
# for hard set this:
solved_row, solved_col = 5, 2

board = board_hard
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
    dim: tuple = ()

    def setup(self):
        """Determine vertical or horizontal and set the length"""
        r, c, n = self.row, self.col, self.nr
        self.set_dimension()
        return self

    def set_dimension(self):
        """How long is this piece"""
        r, c, n = self.row, self.col, self.nr
        l = 0
        h = 0
        while board_by_row_and_col(r, c + l) == n:
            l += 1
        while board_by_row_and_col(r + h, c) == n:
            h += 1
        self.dim = (h, l)
        if l == 1 and h == 1:
            self.ord = 1
        elif l == 1 and h == 2:
            self.ord = 2
        elif l == 2 and h == 1:
            self.ord = 3
        elif l == 2 and h == 2:
            self.ord = 4

    def move(self, row_offs, col_offs, count):
        """Returns
        - None if the move is not possible on the board
        - False if the move is not producing new state
        - True if possible and new state
        """
        d = self.dim
        if row_offs == 1:
            # down, count cells:
            for c in range(count):
                t = self.row + d[0] + c
                for col in range(d[1]):
                    if board_by_row_and_col(t, self.col + col):
                        return None
        elif row_offs == -1:
            # up, count cells:
            for c in range(count):
                t = self.row - c - 1
                for col in range(d[1]):
                    if board_by_row_and_col(t, self.col + col):
                        return None

        elif col_offs == 1:
            # right, count cells:
            for c in range(count):
                t = self.col + d[1] + c
                for row in range(d[0]):
                    if board_by_row_and_col(self.row + row, t):
                        return None

        elif col_offs == -1:
            # left, count cells:
            for c in range(count):
                t = self.col - c - 1
                for row in range(d[0]):
                    if board_by_row_and_col(self.row + row, t):
                        return None
        # Try do the move - then check for having new state:
        or_, oc = self.row, self.col
        self.row, self.col = self.row + count * row_offs, self.col + count * col_offs
        if not have_new_state():
            self.row, self.col = or_, oc
            return False

        # set the board accordingly:
        rm_piece(self.nr)
        add_piece(self)
        return True


def rm_piece(nr):
    """remove piece from board"""
    i = -1
    for r in board:
        i += 1
        j = -1
        for c in r:
            j += 1
            if c == nr:
                board[i][j] = 0


def add_piece(p):
    """add a piece"""
    for r in range(0, p.dim[0]):
        for c in range(0, p.dim[1]):
            board[r + p.row][c + p.col] = p.nr


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
    r = []
    for nr in range(1, len(pieces) + 1):
        p = pieces[nr]
        row, col, ord = p.row, p.col, p.ord
        r.append(100 * ord + 10 * row + col)
    r.sort()
    return tuple(r)

    s += f'{ord}{row}{col}:'
    return s


def have_new_state():
    s = calc_state()
    if not s in states:
        states.add(s)
        return True


def check_solved(prev, piece):
    """Is piece 1 at solved position"""
    p = pieces[1]
    if p.row == solved_row and p.col == solved_col:
        sec = round(time() - t0, 2)
        print_solution(prev, piece, sec)
        sys.exit(0)


clone_state = lambda s: [[k for k in r] for r in s]

tree = []


def print_solution(prev, piece, sec):
    print('\n\nSolution')
    tree.append([{'prev': prev, 'next_states': [{'board': board, 'nr': piece}]}])
    first = True
    move_nr = len(tree)
    nr_moves = len(tree)
    while tree:
        move_nr -= 1
        moves = tree.pop()
        try:
            for move in moves:
                ns = move['next_states']
                for state in ns:
                    piece = state['nr']
                    if state['board'] == prev or first:
                        first = False
                        print('move ', move_nr, piece)
                        print_board(state['board'], piece)
                        prev = move['prev']
                        raise
            # the last one:
            print('error')
            breakpoint()  # FIXME BREAKPOINT
            sys.exit(1)
        except:
            pass
    lmoves = nr_moves - move_nr
    lstates = len(states)
    print(f'Solved in {lmoves} moves (producing {lstates} States). Took {sec}sec.')


# :docs:main_loopklotski
def all_states_one_move_deeper():
    global board
    last_states = tree[-1]
    print('next move: ', len(tree))
    print('breadth is: ', sum([len(k['next_states']) for k in last_states]))
    print('board states: ', len(states))
    print('time', round(time() - t0, 2), 'sec')
    next_states = []
    for s in last_states:
        ns = s['next_states']
        for state in ns:
            state = state['board']
            possbl_mov = []
            for nr in range(1, len(pieces) + 1):
                # try any direction:
                for dir in (1, 0), (-1, 0), (0, 1), (0, -1):
                    count = 0
                    while True:
                        board = clone_state(state)
                        register_pieces()
                        p = pieces[nr]
                        count += 1
                        r = p.move(dir[0], dir[1], count)
                        if r == None:
                            break
                        if r == False:
                            continue
                        check_solved(state, nr)
                        possbl_mov.append(
                            {'board': clone_state(board), 'nr': nr, 'count': count}
                        )

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
    have_new_state()  # register initial state
    tree.append([{'prev': None, 'next_states': [{'board': board, 'nr': 0}]}])
    while True:
        all_states_one_move_deeper()


# :docs:main_loopklotski


if __name__ == '__main__':
    main()
