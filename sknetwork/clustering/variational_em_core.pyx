# distutils: language = c++
# cython: language_level=3
"""
Created on Sep 2020
@author: Clément Bonet <cbonet@enst.fr>
"""
cimport cython
from cython.parallel import prange

import numpy as np
cimport numpy as np
from sknetwork.linalg import normalize

from libc.math cimport log

cdef float eps = np.finfo(float).eps

@cython.boundscheck(False)
@cython.wraparound(False)
def likelihood(int[:] indptr,int[:] indices, float[:,:] membership_probs, float[:] cluster_mean_probs,
		float[:,:] cluster_transition_probs) -> float:
    """Compute the approximated likelihood

    Parameters
    ----------
    indptr:
        Index pointer array of the adjacency matrix of the graph (np.ndarray because of numba, could probably be
        modified in csr_matrix).
    indices:
        Indices array of the adjacency matrix of the graph (np.ndarray because of numba, could probably be
        modified in csr_matrix).
    membership_probs:
        Membership matrix given as a probability over clusters.
    cluster_mean_probs:
        Average value of cluster probability over nodes.
    cluster_transition_probs:
        Probabilities of transition from one cluster to another in one hop.

    Returns
    -------
    likelihood: float
    """
    cdef int n = indptr.shape[0] - 1
    cdef int n_clusters = membership_probs.shape[1]

    cdef float output = np.sum(np.dot(membership_probs,np.log(cluster_mean_probs)))
    cdef float cpt = 0
    cdef int i
    cdef int j
    cdef int cluster_1
    cdef int cluster_2
    cdef float logb
    cdef int ind1, ind2, ind

    for i in prange(n, nogil=True, schedule='guided'):
        for cluster_1 in prange(n_clusters, schedule='guided'):
            for cluster_2 in prange(n_clusters, schedule='guided'):
                for j in range(n):
                    if i != j:
                        logb = log(1 - cluster_transition_probs[cluster_1, cluster_2])
                        cpt += membership_probs[i, cluster_1] * membership_probs[j, cluster_2] * logb

                ind1 = indptr[i]
                ind2 = indptr[i + 1]
                for ind in range(ind1, ind2):
                    j = indices[ind]
                    if j != i:
                        logb = log(cluster_transition_probs[cluster_1, cluster_2]) \
                                - log(1 - cluster_transition_probs[cluster_1, cluster_2])
                        cpt += membership_probs[i, cluster_1] * membership_probs[j, cluster_2] * logb

    return output + cpt / 2 - np.sum(membership_probs * np.log(membership_probs))


@cython.boundscheck(False)
@cython.wraparound(False)
def variational_step(int[:] indptr, int[:] indices, float[:,:] membership_probs, float[:] cluster_mean_probs,
		     float[:,:] cluster_transition_probs):
    """Apply the variational step:
    - update membership_probas

    Parameters
    ----------
    indptr:
        Index pointer array of the adjacency matrix of the graph (np.ndarray because of numba, could probably be
        modified in csr_matrix).
    indices:
        Indices array of the adjacency matrix of the graph (np.ndarray because of numba, could probably be
        modified in csr_matrix).
    membership_probs:
        Membership matrix given as a probability over clusters.
    cluster_mean_probs:
        Average value of cluster probability over nodes.
    cluster_transition_probs:
        Probabilities of transition from one cluster to another in one hop.

    Returns
    -------
    membership_probas:
        Updated membership matrix given as a probability over clusters.
    """
    cdef int n = indptr.shape[0] - 1
    cdef int n_clusters = membership_probs.shape[1]
    cdef float[:,:] log_membership_prob = np.log(np.maximum(membership_probs, eps))
    cdef int i
    cdef int j
    cdef int cluster_1
    cdef int cluster_2
    cdef int ind1, ind2, ind

    for i in range(n):
        for cluster in range(n_clusters):
            log_membership_prob[i, cluster] = log(cluster_mean_probs[cluster])

        for cluster_1 in prange(n_clusters, nogil=True, schedule='guided'):
            for cluster_2 in prange(n_clusters, schedule='guided'):
                for j in range(n):
                    if j != i:
                        log_membership_prob[i, cluster_1] += \
                            membership_probs[j, cluster_2] * log(1 - cluster_transition_probs[cluster_1, cluster_2])

                ind1 = indptr[i]
                ind2 = indptr[i + 1]
                for ind in range(ind1, ind2):
                    j = indices[ind]
                    if j != i:
                        log_membership_prob[i, cluster_1] += \
                            membership_probs[j, cluster_2] * \
                            (log(cluster_transition_probs[cluster_1, cluster_2])
                            - log(1 - cluster_transition_probs[cluster_1, cluster_2]))


    membership_prob = np.exp(log_membership_prob)

    membership_prob = normalize(membership_prob, p=1)

    return np.maximum(membership_prob, eps)
