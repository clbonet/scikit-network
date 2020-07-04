#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Tests for k-cliques count"""
import unittest

from sknetwork.topology import Cliques
from sknetwork.data.test_graphs import *

from scipy.special import comb


class TestCliqueListing(unittest.TestCase):

    def test_empty(self):
        adjacency = test_graph_empty()
        self.assertEqual(Cliques(2).fit_transform(adjacency), 0)

    def test_disconnected(self):
        adjacency = test_graph_disconnect()
        self.assertEqual(Cliques(3).fit_transform(adjacency), 1)

    def test_cliques(self):
        adjacency = test_graph_clique()
        n = adjacency.shape[0]
        self.assertEqual(Cliques(3).fit_transform(adjacency), comb(n, 3, exact=True))

        self.assertEqual(Cliques(4).fit_transform(adjacency), comb(n, 4, exact=True))