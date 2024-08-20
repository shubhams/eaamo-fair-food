import os,sys
import numpy as np
from prepare_food_data import *
sys.path.insert(0, '../../fair_classification/') # the code for fair classification is in this directory
import utils as ut
import loss_funcs as lf # loss funcs that can be optimized subject to various constraints
from collections import Counter
import json


def test_adult_data(window):
	

	""" Load the food data """
	X, y, x_control, test_idx, perm, og_cols = load_food_data(window) # set the argument to none, or no arguments if you want to test with the whole data -- we are subsampling for performance speedup
	ut.compute_p_rule(x_control["sanitarian"], y) # compute the p-rule in the original data


	""" Split the data into train and test """
	X = ut.add_intercept(X) # add intercept to X before applying the linear classifier
	x_train, y_train, x_control_train, x_test, y_test, x_control_test = ut.split_food(X, y, x_control, test_idx)



	apply_fairness_constraints = None
	apply_accuracy_constraint = None
	sep_constraint = None

	loss_function = lf._logistic_loss
	# loss_function = lf._logistic_loss_l2_reg
	sensitive_attrs = ["sanitarian"]
	sensitive_attrs_to_cov_thresh = {}
	gamma = None

	def train_test_classifier():
		w = ut.train_model(x_train, y_train, x_control_train, loss_function, apply_fairness_constraints, apply_accuracy_constraint, sep_constraint, sensitive_attrs, sensitive_attrs_to_cov_thresh, gamma)
		train_score, test_score, correct_answers_train, correct_answers_test = ut.check_accuracy(w, x_train, y_train, x_test, y_test, None, None)
		distances_boundary_test = (np.dot(x_test, w)).tolist()
		all_class_labels_assigned_test = np.sign(distances_boundary_test)
		correlation_dict_test = ut.get_correlations(None, None, all_class_labels_assigned_test, x_control_test, sensitive_attrs)
		cov_dict_test = ut.print_covariance_sensitive_attrs(None, x_test, distances_boundary_test, x_control_test, sensitive_attrs)
		p_rule = ut.print_classifier_fairness_stats([test_score], [correlation_dict_test], [cov_dict_test], sensitive_attrs[0])	
		coef = dict()
		for key, val in zip(og_cols, w[1:]):
			coef[key] = val
		print(f"coefficients: {json.dumps(coef)}")
		return w, p_rule, test_score

	def train_test_all_classifier():
		w = ut.train_model(x_train, y_train, x_control_train, loss_function, apply_fairness_constraints, apply_accuracy_constraint, sep_constraint, sensitive_attrs, sensitive_attrs_to_cov_thresh, gamma)
		train_score, test_score, correct_answers_train, correct_answers_test = ut.check_accuracy(w, x_train, y_train, X, y, None, None)
		distances_boundary_test = (np.dot(X, w)).tolist()
		all_class_labels_assigned_test = np.sign(distances_boundary_test)
		correlation_dict_test = ut.get_correlations(None, None, all_class_labels_assigned_test, x_control, sensitive_attrs)
		cov_dict_test = ut.print_covariance_sensitive_attrs(None, X, distances_boundary_test, x_control, sensitive_attrs)
		p_rule = ut.print_classifier_fairness_stats([test_score], [correlation_dict_test], [cov_dict_test], sensitive_attrs[0])	
		return w, p_rule, test_score, distances_boundary_test


	# """ Classify the data while optimizing for accuracy """
	# print()
	# print("== Unconstrained (original) classifier ==")
	# # all constraint flags are set to 0 since we want to train an unconstrained (original) classifier
	# apply_fairness_constraints = 0
	# apply_accuracy_constraint = 0
	# sep_constraint = 0
	# w_uncons, p_uncons, acc_uncons = train_test_classifier()
	
	""" Now classify such that we optimize for accuracy while achieving perfect fairness """
	apply_fairness_constraints = 1 # set this flag to one since we want to optimize accuracy subject to fairness constraints
	apply_accuracy_constraint = 0
	sep_constraint = 0
	allowed_thresh = 0.0
	sensitive_attrs_to_cov_thresh = {"sanitarian":{
		0:allowed_thresh, 
		1:allowed_thresh, 
		2:allowed_thresh, 
		3:allowed_thresh, 
		4:allowed_thresh, 
		5:allowed_thresh
		}
	}
	print()
	print("== Classifier with fairness constraint ==")
	# w_f_cons, p_f_cons, acc_f_cons  = train_test_classifier()

	# test on complete dataset to get scores
	_, _, _, scores = train_test_all_classifier()
	idx_to_score_map = dict()
	for key, val in zip(perm, scores):
		idx_to_score_map[key] = val
	list_to_write = list()
	for idx in range(len(scores)):
		list_to_write.append(idx_to_score_map[idx])
	list_to_write = np.asarray(list_to_write)
	np.savetxt(f"../../food_scores/zafar_scores_{window}_{allowed_thresh}.csv", list_to_write, delimiter=",")

	# """ Classify such that we optimize for fairness subject to a certain loss in accuracy """
	# apply_fairness_constraints = 0 # flag for fairness constraint is set back to0 since we want to apply the accuracy constraint now
	# apply_accuracy_constraint = 1 # now, we want to optimize fairness subject to accuracy constraints
	# sep_constraint = 0
	# gamma = 0.5 # gamma controls how much loss in accuracy we are willing to incur to achieve fairness -- increase gamme to allow more loss in accuracy
	# print("== Classifier with accuracy constraint ==")
	# w_a_cons, p_a_cons, acc_a_cons = train_test_classifier()	

	# """ 
	# Classify such that we optimize for fairness subject to a certain loss in accuracy 
	# In addition, make sure that no points classified as positive by the unconstrained (original) classifier are misclassified.

	# """
	# apply_fairness_constraints = 0 # flag for fairness constraint is set back to0 since we want to apply the accuracy constraint now
	# apply_accuracy_constraint = 1 # now, we want to optimize accuracy subject to fairness constraints
	# sep_constraint = 1 # set the separate constraint flag to one, since in addition to accuracy constrains, we also want no misclassifications for certain points (details in demo README.md)
	# gamma = 1000.0
	# print("== Classifier with accuracy constraint (no +ve misclassification) ==")
	# w_a_cons_fine, p_a_cons_fine, acc_a_cons_fine  = train_test_classifier()

	return

def main():
	for i in range(0,19):
		test_adult_data(i)


if __name__ == '__main__':
	main()