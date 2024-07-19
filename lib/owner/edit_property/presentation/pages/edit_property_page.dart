import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:smart_real_estate/core/helper/local_data/shared_pref.dart';
import 'package:smart_real_estate/core/utils/images.dart';
import 'package:smart_real_estate/core/utils/styles.dart';
import 'package:smart_real_estate/features/client/property_details/presentation/pages/property_details_screen.dart';
import 'package:smart_real_estate/owner/edit_property/domain/test.dart';
import 'package:smart_real_estate/owner/edit_property/domain/update_list_attributes_repository.dart';
import 'package:smart_real_estate/owner/edit_property/domain/update_property_repository.dart';
import 'package:smart_real_estate/owner/edit_property/presentation/widgets/address_section_edit.dart';
import 'package:smart_real_estate/owner/edit_property/presentation/widgets/category_section_edit.dart';
import 'package:smart_real_estate/owner/edit_property/presentation/widgets/chip_feature_widget.dart';

import '../../../../core/constant/app_constants.dart';
import '../../../../features/client/alarm/presentation/manager/category/category_cubit.dart';
import '../../../../features/client/alarm/presentation/pages/add_alarm_screen.dart';
import '../../../../features/client/home/data/models/category/category_model.dart';
import '../../../../features/client/home/widgets/chip_widget_home.dart';
import '../../../../features/client/property_details/data/model/image_model.dart';
import '../../../../features/client/property_details/presentation/manager/property_details/property_details_cubit.dart';
import '../../../../features/client/property_details/presentation/manager/property_details/property_details_state.dart';
import '../../../add_property/presentation/pages/fifth_images_add_property.dart';
import '../../domain/get_features_repository.dart';

class EditPropertyPage extends StatefulWidget {
   const EditPropertyPage({super.key, required this.propertyId, required this.token});
   final int propertyId;
   final String token;

  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends State<EditPropertyPage> {


  TextEditingController propertyName = TextEditingController();
  TextEditingController propertyDescription = TextEditingController();
  TextEditingController propertyPrice = TextEditingController();
  TextEditingController propertySize = TextEditingController();
  TextEditingController propertyAddressLineOne = TextEditingController();
  TextEditingController propertyAddressLineTwo = TextEditingController();

  /// first add property

  List<Map<String, dynamic>> features = [];
  List<bool> chipSelected2 = [];
  late List<bool> defaultChipSelected;

  CategoryModel? mainCategory;
  CategoryModel? subCategory;
  int? parentId;

  var globalpropertyDetails;
  /// second api attributes
  bool _loading = false;
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  /// image section api
  int numberImages = 0;
  List<File> _images = [];
  bool isLoading = false;
  List<ImageModel2> imageList=[];
  String? newImagePath;


  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _images.addAll(pickedFiles.map((pickedFile) => File(pickedFile.path)));
      });
    }
  }

  Future<void> _uploadSingleImage(File image) async {
    final url = Uri.parse('${AppConstants.baseUrl}api/image/property/create/');

    final request = http.MultipartRequest('POST', url);

    request.fields['object_id'] = widget.propertyId.toString();

    String fileName = image.path.split('/').last;
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    request.headers['Authorization'] = 'token ${widget.token}';

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });
    final client = await ProgressClient(http.Client(), onProgress: (bytes, totalBytes) {
      setState(() {
        _uploadProgress = bytes / totalBytes;
      });
    });

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 201) {
        // print(await response.stream.bytesToString());

        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);
        setState(() {
          newImagePath = jsonResponse['image'];
        });

        Get.snackbar("Upload Successful", "Image URL: $newImagePath");
      } else {
        print(response.reasonPhrase);
        Get.snackbar("not uploaded", "try edit the property");
      }
    } finally {
      client.close();
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }



  /// google map


  @override
  void initState() {
    super.initState();
    getToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }




    /// fetch data from the server
  Future<void> fetchAndSetFeatures() async {
    var fetchedFeatures = await FeatureRepository.fetchFeatures(categoryId: 25); // Example category ID
    setState(() {
      features = fetchedFeatures;
      chipSelected2 = List.filled(features.length, false);
    });
  }
  void _fetchData() async{

    final mainCategory = context.read<CategoryAlarmCubit>();
    final propertyDetails = context.read<PropertyDetailsCubit>();

    await Future.wait([

    ]);
    await Future.wait([
      mainCategory.fetchMainCategory(),
      propertyDetails.getPropertyDetails(widget.propertyId, widget.token),
    ]);


  }

  /// function to get user id and token

  String? token;

  List<int> selectedIds = [];
  Future<void> getToken() async {
    final myToken = await SharedPrefManager.getData(AppConstants.token);

    setState(() {
      token = myToken ?? " ";
    });

    print("my toooooooookennnnn $token");
  }
  void onChipClick(int index) {
    setState(() {
      chipSelected2[index] = !chipSelected2[index];
      if (chipSelected2[index]) {
        selectedIds.add(features[index]['id']);
      } else {
        selectedIds.remove(features[index]['id']);
      }
      print('Selected IDs: $selectedIds');
    });
  }



  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async{
        _fetchData();
      },
      child: Scaffold(
        body: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: SvgPicture.asset(Images.halfCircle),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: BlocBuilder<PropertyDetailsCubit, PropertyDetailsState>(
                      builder: (context, state) {
                        if (state is PropertyDetailsLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (state is PropertyDetailsSuccess) {
                          final propertyDetails = state.propertyDetails;

                          propertyDetails.address!.line1.toString();
                          imageList = state.propertyDetails.image!.map((imageModel) => ImageModel2(
                            image: imageModel.image,
                            id: imageModel.id,
                          )).toList();


                          globalpropertyDetails = propertyDetails;



                          /// for name and description
                          propertyName.text = propertyDetails.name! ?? "";
                          propertyDescription.text = propertyDetails.description!?? "";
                          propertyPrice.text = propertyDetails.price! ?? "";
                          propertySize.text = propertyDetails.size!.toString() ?? "";

                          /// for type list

                          /// image section
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// appbar
                              const Text("تعديل العقار", style: fontMediumBold,),
                              const SizedBox(height: 10.0,),
                              /// Display property image and some details
                              GestureDetector(
                                onTap: () {
                                  // Navigate to the edit page
                                  Get.to(()=> PropertyDetailsScreen(id: widget.propertyId, token: widget.token));
                                },
                                child: _buildPropertyView(context,imageList ?? [], propertyDetails),

                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: propertyName,
                                decoration: InputDecoration(
                                  labelText: 'اسم العقار',
                                  prefixIcon: const Icon(Icons.home),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: propertyDescription,
                                decoration: InputDecoration(
                                  labelText: 'وصف العقار',
                                  prefixIcon: const Icon(Icons.description),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                maxLines: null, // Makes the TextField expandable
                                minLines: 1, // Initial height of the TextField
                                keyboardType: TextInputType.multiline, // Allows multiline input
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: propertyPrice,
                                decoration: InputDecoration(
                                  labelText: 'السعر',
                                  prefixIcon: const Icon(Icons.attach_money),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.number, // Ensures the keyboard is numeric
                              ),
                              const SizedBox(height: 16),

                              /// category section
                              const SizedBox(height: 16),
                              CategorySectionEdit(
                                selectedCategoryId: propertyDetails.category!.parent!,
                                selectedSubCategoryId: propertyDetails.category!.id!,
                                token: widget.token,
                                propertyDetails: propertyDetails,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: propertySize,
                                decoration: InputDecoration(
                                  labelText: 'المساحة',
                                  prefixIcon: const Icon(Icons.square_foot),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.number, // Ensures the keyboard is numeric
                              ),
                              const SizedBox(height: 16),
                              AddressSectionEdit(propertyDetails: propertyDetails,),
                              const SizedBox(height: 16),
                              const Text(
                                'صور العقار',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8.0,
                                children: [
                                  ...imageList.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    ImageModel2 imageModel = entry.value;
                                    return _buildPropertyImage(imageModel, index);
                                  }),
                                  _buildAddImageButton(),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'البيئة / المرافق',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                runSpacing: 10,
                                spacing: 10,
                                children: [
                                  ...List.generate(
                                    features.length,
                                        (index) => Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                                      child: ChipFeatureWidget(
                                        feature: features[index],
                                        chipSelected: chipSelected2,
                                        onChipClick: () => onChipClick(index),
                                        index: index,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(jsonEncode(propertyDetails)),

                              const SizedBox(height: 100),


                              /// Displaying property rest details


                              /// Displaying property Features and Attribute
                              const SizedBox(height: 5.0,),

                              const SizedBox(height: 5.0,),


                              /// display property promoter details
                              const SizedBox(height: 10.0,),


                              /// display GoogleMap and address details
                              const SizedBox(height: 10.0,),


                              /// display reviews and Rating




                            ],
                          );
                        } else if (state is PropertyDetailsError) {
                          return Center(
                            child: Text('Error: ${state.error}'),
                          );
                        } else {
                          return const SizedBox(); // Return an empty widget if state is not recognized
                        }
                      },
                    ),
                  ),
                ),
              ),

              /// button to update the property
              Positioned(
                bottom: 0,
                right: 0,
                left: 0,
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: InkWell(
                    onTap: _updateProperty,
                    child: Container(
                      height: 70,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: _loading?const CircularProgressIndicator():Text(
                          "update",
                          style: fontMediumBold.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _updateProperty() async {
    // Get data from text fields
    String realName = propertyName.text;
    String realPrice = propertyPrice.text;
    String realDescription = propertyDescription.text;
    double realSize = double.parse(propertySize.text);
    final realSubCategoryId = await SharedPrefManager.getData(AppConstants.editSubCategoryId);
    Map<String, dynamic>? realAttributesValues = await SharedPrefManager.getMap(AppConstants.editPropertyAttributes);
    // Map<String, dynamic>? realStateId = await SharedPrefManager.getMap(AppConstants.);




    /// update the attributes
    if (realAttributesValues != null && realAttributesValues.isNotEmpty) {
      await SharedPrefManager.deleteData(AppConstants.editPropertyAttributes);

      Map<String, dynamic> payload = {
        "property_id": globalpropertyDetails.id,
        "attributes_values": realAttributesValues
      };

      await UpdateListAttributesRepository.updatePropertyValue(payload, widget.token);
    }


    /// Create a map to store the changes
    Map<String, dynamic> updates = {};

    // Check if any of the properties have changed and add them to the updates map
    if (globalpropertyDetails.name != realName) {
      updates['name'] = realName;
    }
    if (realSubCategoryId != null && realSubCategoryId != globalpropertyDetails.category.id) {
      await SharedPrefManager.deleteData(AppConstants.editSubCategoryId);
      updates['category'] = realSubCategoryId;
    }
    if (globalpropertyDetails.price != realPrice) {
      updates['price'] = realPrice.toString();
    }
    if (globalpropertyDetails.description != realDescription) {
      updates['description'] = realDescription;
    }
    if (globalpropertyDetails.size != realSize) {
      updates['size'] = realSize;
    }


    /// If there are any updates, make the API call
    if (updates.isNotEmpty) {
      setState(() {
        _loading = true;
      });
      await UpdatePropertyRepository.update(
        body: updates,
        propertyId: globalpropertyDetails.id,
        token: widget.token,
      );
      setState(() {
        _loading = false;
      });
      print(updates);
      // Handle response if necessary
    }

    // Print the updated property details
  }

  Widget _buildPropertyImage(ImageModel2 imageUrl, int index) {
    return Stack(
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              "${AppConstants.baseUrl3}${imageUrl.image!}",
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: InkWell(
            onTap: () {
              showDeleteConfirmationDialog(context, () async {
                try {
                  setState(() {
                    _loading = true;
                  });
                  var headers = {'Authorization': 'token ${widget.token}'};
                  var request = http.Request(
                    'DELETE',
                    Uri.parse(
                      '${AppConstants.baseUrl}api/image/${imageUrl.id!}/delete/',
                    ),
                  );

                  request.headers.addAll(headers);

                  http.StreamedResponse response = await request.send();

                  if (response.statusCode == 204) {
                    Navigator.of(context).pop();
                    setState(() {
                      _loading = false;
                      imageList.removeAt(index); // Remove the image from the list
                    });
                    Get.snackbar("Successfully deleted", "Cool");
                    print(await response.stream.bytesToString());
                  } else {
                    Get.snackbar("Error to delete", "Try again", colorText: Colors.red);
                    setState(() {
                      _loading = false;
                    });
                    print(response.reasonPhrase);
                  }
                } catch (e) {
                  setState(() {
                    _loading = false;
                  });

                  Get.snackbar("Error to delete", "Try again $e", colorText: Colors.red);
                }
              });
            },
            child: CircleAvatar(
              backgroundColor: Theme.of(context).cardColor,
              radius: 12,
              child: const Icon(Icons.close, size: 16, color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: () async {
        // Add image logic
        await _pickImage();

        for (File image in _images) {
          await _uploadSingleImage(image);
        }

      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: const Icon(Icons.add, size: 30, color: Colors.grey),
      ),
    );
  }


  Widget _buildPropertyView(BuildContext context, List<ImageModel2> imageList, final propertyDetails) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Theme.of(context).cardColor,
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: double.infinity,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.0),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(("${AppConstants.baseUrl3}${(imageList.isEmpty?"":imageList.first.image)}" == AppConstants.baseUrl3 && imageList.isEmpty
                        ?AppConstants.noImageUrl
                        :"${AppConstants.baseUrl3}${imageList[0].image}"),
                    ),
                    fit: BoxFit.cover
                  )
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(propertyDetails.name, style: fontMedium,maxLines: 1, overflow: TextOverflow.ellipsis,),
                    Text("${propertyDetails.rate.toString()}⭐", style: fontSmallBold,maxLines: 1, overflow: TextOverflow.ellipsis,),
                    Text("${propertyDetails.address!.line1}", style: fontSmallBold,maxLines: 1, overflow: TextOverflow.ellipsis,),
                    Text("${propertyDetails.price}", style: fontSmallBold,maxLines: 1, overflow: TextOverflow.ellipsis,),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void showDeleteConfirmationDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure to delete?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: onConfirm,
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }


  /// google map to edit address



}