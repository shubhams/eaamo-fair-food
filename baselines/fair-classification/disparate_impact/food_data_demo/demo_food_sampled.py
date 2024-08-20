import os,sys
import numpy as np
from prepare_food_data import *
sys.path.insert(0, '../../fair_classification/') # the code for fair classification is in this directory
import utils as ut
import loss_funcs as lf # loss funcs that can be optimized subject to various constraints
from collections import defaultdict
import json
import pandas as pd


def test_adult_data(window, classifier, sensitive_attrs, sample_method, sample_size):
	

	""" Load the food data """
	if sample_method == "no_sample":
		X, y, x_control, test_idx, perm, og_cols = load_food_data(window)
	else:
		X, y, x_control, test_idx, perm, og_cols = load_food_data_sampled_by_dem(window, sample_method, sample_size) # set the argument to none, or no arguments if you want to test with the whole data -- we are subsampling for performance speedup
	ut.compute_p_rule(x_control[sensitive_attrs[0]], y) # compute the p-rule in the original data


	""" Split the data into train and test """
	X = ut.add_intercept(X) # add intercept to X before applying the linear classifier
	x_train, y_train, x_control_train, x_test, y_test, x_control_test = ut.split_food(X, y, x_control, test_idx)



	apply_fairness_constraints = None
	apply_accuracy_constraint = None
	sep_constraint = None

	loss_function = lf._logistic_loss
	# loss_function = lf._logistic_loss_l2_reg
	sensitive_attrs_to_cov_thresh = {}
	gamma = None

	def train_test_classifier():
		w = ut.train_model(x_train, y_train, x_control_train, loss_function, apply_fairness_constraints, apply_accuracy_constraint, sep_constraint, sensitive_attrs, sensitive_attrs_to_cov_thresh, gamma)
		train_score, test_score, correct_answers_train, correct_answers_test = ut.check_accuracy(w, x_train, y_train, x_test, y_test, None, None)
		distances_boundary_test = (np.dot(x_test, w)).tolist()
		all_class_labels_assigned_test = np.sign(distances_boundary_test)
		dp_violation = ut.get_fairness_metric(all_class_labels_assigned_test, x_control_test, y_test, sensitive_attrs, criteria='dp')
		eopp_violation = ut.get_fairness_metric(all_class_labels_assigned_test, x_control_test, y_test, sensitive_attrs, criteria='eopp')
		classification_metrics = ut.get_classification_metrics(all_class_labels_assigned_test, y_test)
		coef = dict()
		for key, val in zip(og_cols, w[1:]):
			coef[key] = val
		print(f"coefficients: {json.dumps(coef)}")
		return classification_metrics, dp_violation, eopp_violation

	def train_test_all_classifier():
		w = ut.train_model(x_train, y_train, x_control_train, loss_function, apply_fairness_constraints, apply_accuracy_constraint, sep_constraint, sensitive_attrs, sensitive_attrs_to_cov_thresh, gamma)
		train_score, test_score, correct_answers_train, correct_answers_test = ut.check_accuracy(w, x_train, y_train, X, y, None, None)
		distances_boundary_test = (np.dot(X, w)).tolist()
		all_class_labels_assigned_test = np.sign(distances_boundary_test)
		ut.get_fairness_metric(all_class_labels_assigned_test, x_control, y, sensitive_attrs, criteria='dp')
		ut.get_fairness_metric(all_class_labels_assigned_test, x_control, y, sensitive_attrs, criteria='eopp')
		correlation_dict_test = ut.get_correlations(None, None, all_class_labels_assigned_test, x_control, sensitive_attrs)
		cov_dict_test = ut.print_covariance_sensitive_attrs(None, X, distances_boundary_test, x_control, sensitive_attrs)
		p_rule = ut.print_classifier_fairness_stats([test_score], [correlation_dict_test], [cov_dict_test], sensitive_attrs[0])	
		return w, p_rule, test_score, distances_boundary_test

	
	if classifier == "zafar":
		""" Now classify such that we optimize for accuracy while achieving perfect fairness """
		apply_fairness_constraints = 1 # set this flag to one since we want to optimize accuracy subject to fairness constraints
		apply_accuracy_constraint = 0
		sep_constraint = 0
		allowed_thresh = 0.0
		# sensitive_attrs_to_cov_thresh = {"dem_group":{
		# 	0:allowed_thresh, 
		# 	1:allowed_thresh, 
		# 	2:allowed_thresh, 
		# 	3:allowed_thresh, 
		# 	4:allowed_thresh, 
		# 	5:allowed_thresh
		# 	}
		# }
		thresh_dict = dict()
		for x in np.unique(x_control[sensitive_attrs[0]]):
			thresh_dict[x] = allowed_thresh
		sensitive_attrs_to_cov_thresh[list(x_control.keys())[0]] = thresh_dict
		print()
		print("== Classifier with fairness constraint ==")

		# # test on complete dataset to get scores
		# _, _, _, scores = train_test_all_classifier()
		# idx_to_score_map = dict()
		# for key, val in zip(perm, scores):
		# 	idx_to_score_map[key] = val
		# list_to_write = list()
		# for idx in range(len(scores)):
		# 	list_to_write.append(idx_to_score_map[idx])
		# list_to_write = np.asarray(list_to_write)
		# # np.savetxt(f"../../food_scores/zafar_scores_{window}_{allowed_thresh}.csv", list_to_write, delimiter=",")

		# run only on test data
		metrics, dp_violation, eopp_violation = train_test_classifier()

	else:
		""" Classify the data while optimizing for accuracy """
		print()
		print("== Unconstrained (original) classifier ==")
		# all constraint flags are set to 0 since we want to train an unconstrained (original) classifier
		apply_fairness_constraints = 0
		apply_accuracy_constraint = 0
		sep_constraint = 0
		metrics, dp_violation, eopp_violation = train_test_classifier()

	return metrics, dp_violation, eopp_violation

def main():
	list_dict = defaultdict(list)
	# classifier = "zafar", "basicLR"
	classifier = "zafar"
	# sensitive_attrs = ["sanitarian"], ["dem_group"]
	sensitive_attrs = ["sanitarian"]
	# sample_method = "prob", "round", "no_sample"
	sample_method = "no_sample"
	# sample_size = 1, 5
	sample_size = 1

	# experiment groups:
	# zafar-dem_group-prob5
	# zafar-dem_group-prob1
	# zafar-dem_group-round
	# zafar-sanitarian-no_sample
	# basicLR-dem_group-prob5
	# basicLR-dem_group-prob1
	# basicLR-dem_group-round
	# basicLR-sanitarian-no_sample
	

	for i in range(0,19):
		metrics, dp, eopp = test_adult_data(i, classifier, sensitive_attrs, sample_method, sample_size)
		list_dict["precision"].append(metrics[0])
		list_dict["recall"].append(metrics[1])
		list_dict["f1"].append(metrics[2])
		list_dict["support"].append(metrics[3])
		list_dict["dp violation"].append(dp)
		list_dict["eopp violation"].append(eopp)
		# break
	df_dict = {
		"precision":list_dict["precision"],
		"recall":list_dict["recall"],
		"f1":list_dict["f1"],
		"support":list_dict["support"],
		"dp_violation":list_dict["dp violation"], 
		"eopp_violation":list_dict["eopp violation"]
	}
	df = pd.DataFrame(df_dict)
	# df.to_csv(f"../../fairness_scores/{classifier}-{sensitive_attrs[0]}-{sample_method}-{sample_size}.csv", index=False)

if __name__ == '__main__':
	main()