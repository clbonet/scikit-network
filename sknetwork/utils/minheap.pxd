# distutils: language = c++
# cython: language_level=3
# cython: linetrace=True
# distutils: define_macros=CYTHON_TRACE_NOGIL=1
"""
Created on Jun 3, 2020
@author: Julien Simonnet <julien.simonnet@etu.upmc.fr>
@author: Yohann Robert <yohann.robert@etu.upmc.fr>
"""
from libcpp.vector cimport vector

cdef inline int parent(int i):
    """Index of the parent node of i in the tree."""
    return (i - 1) // 2

cdef inline int left(int i):
    """Index of the left child of i in the tree."""
    return 2 * i + 1

cdef inline int right(int i):
    """Index of the right child of i in the tree."""
    return 2 * i + 2

cdef class MinHeap:

    cdef vector[int] val, pos
    cdef int size

    cdef int pop_min(self, int[:] scores)
    cdef bint empty(self)
    cdef void swap(self, int x, int y)
    cdef void insert_key(self, int k, int[:] scores)
    cdef void decrease_key(self, int i, int[:] scores)
    cdef void min_heapify(self, int i, int[:] scores)
