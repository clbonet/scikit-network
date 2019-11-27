#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""tests for eig"""

import unittest

import numpy as np

from sknetwork.linalg import LanczosEig, HalkoEig, SparseLR
from sknetwork.data import miserables, karate_club


# noinspection PyMissingOrEmptyDocstring
def eigenvector_err(matrix, eigenvectors, eigenvalues):
    err = matrix.dot(eigenvectors) - eigenvectors * eigenvalues
    return np.linalg.norm(err)


# noinspection DuplicatedCode,PyMissingOrEmptyDocstring
class TestSolvers(unittest.TestCase):

    def setUp(self):
        self.adjacency = miserables()
        n = self.adjacency.shape[0]
        x = np.random.random(n)
        self.slr = SparseLR(self.adjacency, [(x, x)])

    def test_lanczos(self):
        solver = LanczosEig('LM')
        solver.fit(self.adjacency, 2)
        self.assertEqual(len(solver.eigenvalues_), 2)
        self.assertAlmostEqual(eigenvector_err(self.adjacency, solver.eigenvectors_, solver.eigenvalues_), 0)

        solver.fit(self.slr, 2)
        self.assertEqual(len(solver.eigenvalues_), 2)
        self.assertAlmostEqual(eigenvector_err(self.slr, solver.eigenvectors_, solver.eigenvalues_), 0)

        karate = karate_club()
        solver = LanczosEig('SM')
        solver.fit(karate, 2)
        self.assertEqual(len(solver.eigenvalues_), 2)
        self.assertAlmostEqual(eigenvector_err(karate, solver.eigenvectors_, solver.eigenvalues_), 0)

    def test_halko(self):
        solver = HalkoEig('LM')
        solver.fit(self.adjacency, 2)
        self.assertEqual(len(solver.eigenvalues_), 2)
        self.assertAlmostEqual(eigenvector_err(self.adjacency, solver.eigenvectors_, solver.eigenvalues_), 0)

        solver.fit(self.slr, 2)
        self.assertEqual(len(solver.eigenvalues_), 2)
        self.assertAlmostEqual(eigenvector_err(self.slr, solver.eigenvectors_, solver.eigenvalues_), 0, 6)

        solver = HalkoEig('SM')
        solver.fit(self.adjacency, 2)
        self.assertEqual(len(solver.eigenvalues_), 2)
        # self.assertAlmostEqual(eigenvector_err(self.adjacency, solver.eigenvectors_, solver.eigenvalues_), 0)

    def test_compare_solvers(self):
        lanczos = LanczosEig('LM')
        halko = HalkoEig('LM')

        lanczos.fit(self.adjacency, 2)
        halko.fit(self.adjacency, 2)
        self.assertAlmostEqual(np.linalg.norm(lanczos.eigenvalues_ - halko.eigenvalues_), 0.)

        lanczos.fit(self.slr, 2)
        halko.fit(self.slr, 2)
        self.assertAlmostEqual(np.linalg.norm(lanczos.eigenvalues_ - halko.eigenvalues_), 0.)
