import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todo/db_helper/dbHelper.dart';
import 'package:todo/model/task_model.dart';
import 'package:todo/util/utils.dart';
import 'package:todo/view_model/controller/home_controller.dart';

class NewTaskController extends GetxController {
  DateTime? pickedDate;
  final DbHelper db = DbHelper();
  RxInt selectedImage = 0.obs;
  RxBool lowPeriority = false.obs;
  RxBool labelFocus = false.obs;
  RxBool categoryFocus = false.obs;
  RxBool descriptionFocus = false.obs;
  RxString selectedDate = ''.obs;
  RxString startTime = ''.obs;
  RxString endTime = ''.obs;
  RxBool loading = false.obs;
  final homeController = Get.put(HomeController());
  final label = TextEditingController().obs;
  final description = TextEditingController().obs;
  final category = TextEditingController().obs;

  late CollectionReference tasksCollection;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    tasksCollection = _firestore.collection('tasks');
  }

  picStartTime(BuildContext context) async {
    var picker =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picker != null) {
      startTime.value =
          '${Utils.addPrefix(picker.hourOfPeriod.toString())}:${Utils.addPrefix(picker.minute.toString())}:${picker.period.name.toUpperCase()}';
    }
  }

  picEndTime(BuildContext context) async {
    var picker =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picker != null) {
      endTime.value =
          '${Utils.addPrefix(picker.hourOfPeriod.toString())}:${Utils.addPrefix(picker.minute.toString())}:${picker.period.name.toUpperCase()}';
    }
  }

  showDatePick(BuildContext context) async {
    var picker = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 7)));
    if (picker != null) {
      pickedDate = picker;
      selectedDate.value =
          '${Utils.addPrefix(picker.day.toString())}/${Utils.addPrefix(picker.month.toString())}/${picker.year}';
    }
  }

  changeImage(int index) {
    selectedImage.value = index;
  }

  setLabelFocus() {
    labelFocus.value = true;
    categoryFocus.value = false;
    descriptionFocus.value = false;
  }

  setCategoryFocus() {
    labelFocus.value = false;
    categoryFocus.value = true;
    descriptionFocus.value = false;
  }

  setDescriptionFocus() {
    labelFocus.value = false;
    categoryFocus.value = false;
    descriptionFocus.value = true;
  }

  onTapOutside() {
    labelFocus.value = false;
    categoryFocus.value = false;
    descriptionFocus.value = false;
  }

  Future<void> createTask(TaskModel task) async {
    try {
      await tasksCollection.add(task.toMap());

      // Optionally, show a success message or navigate to another screen
      Get.snackbar('Success', 'Task created successfully');
      label.value.clear();
      description.value.clear();
      category.value.clear();
      selectedDate.value = '';
      selectedImage.value = 0;
      lowPeriority.value = true;
      startTime.value = '';
      endTime.value = '';
      loading.value = false;
      Get.back();
    } catch (e) {
      if (e is FirebaseException) {
        print(
            'FirebaseException code: ${e.code}'); // Print the specific Firebase error code
        print(
            'FirebaseException message: ${e.message}'); // Print the detailed error message
      }
      // Handle errors
      // Get.snackbar('Error', 'Failed to create task: $e');
      print('Error creating task: $e');
    }
  }

  insertTask(BuildContext context) {
    if (label.value.text.toString().isEmpty) {
      Utils.showSnackBar(
        'Warning',
        'Enter valid label',
        const Icon(
          Icons.warning_amber_rounded,
          color: Colors.red,
        ),
      );
      return;
    }
    if (category.value.text.toString().isEmpty) {
      Utils.showSnackBar(
        'Warning',
        'Enter Correct Category',
        const Icon(
          Icons.warning_amber_rounded,
          color: Colors.red,
        ),
      );
      return;
    }
    if (selectedDate.isEmpty) {
      // selectedDate.value =
      //     '${Utils.addPrefix(DateTime.now().day.toString())}/${Utils.addPrefix(DateTime.now().month.toString())}/${Utils.addPrefix(DateTime.now().year.toString())}';
      showDatePick(context);
    }
    if (startTime.isEmpty) {
      picStartTime(context);
      return;
    }
    if (endTime.isEmpty) {
      picEndTime(context);
      return;
    }
    loading.value = true;

    db
        .insert(TaskModel(
            key: DateTime.now().microsecondsSinceEpoch.toString(),
            startTime: startTime.value,
            endTime: endTime.value,
            date: selectedDate.value,
            periority: lowPeriority.value ? 'Low' : 'High',
            description: description.value.text.toString(),
            category: category.value.text.toString(),
            title: label.value.text.toString(),
            image: selectedImage.value.toString(),
            show: 'yes',
            status: 'unComplete'))
        .then((value) {
      // homeController.getTasks();

      Duration dif = pickedDate!.difference(DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day));
      createTask(value);
      homeController.list[dif.inDays].add(value);
      Timer(const Duration(seconds: 1), () {
        loading.value = false;
        Get.back();
        Utils.showSnackBar(
          'Successful',
          'Task is created',
          const Icon(
            Icons.done,
            color: Colors.white,
          ),
        );
      });
    });
  }
}
