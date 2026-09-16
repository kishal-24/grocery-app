import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/screens/login/mobile_login_screen.dart';

import '../../bloc/location/location_bloc.dart';
import '../../bloc/location/location_event.dart';
import '../../bloc/location/location_state.dart';


class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() =>
      _LocationScreenState();
}

class _LocationScreenState
    extends State<LocationScreen> {

  final TextEditingController searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();

    context.read<LocationBloc>().add(
      const ClearLocationSearchEvent(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: BlocConsumer<LocationBloc, LocationState>(
          listener: (context, state) {

            if (state.status ==
                LocationStatus.submitted) {

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const MobileLoginScreen(),
                ),
              );
            }



            if (state.status ==
                LocationStatus.failure &&
                state.errorMessage != null) {

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  content:
                  Text(state.errorMessage!),
                ),
              );
            }
          },

          builder: (context, state) {

            return SingleChildScrollView(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),
                  Image.asset(
                    'assets/illustration.png',
                    height: 300,
                    width: double.infinity,
                    fit:BoxFit.contain,
                  ),

                  const SizedBox(height: 20),


                  const Text(
                    'Select Your Location',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 35,
                    ),
                    child: Text(
                      "Switch on your location to stay in tune "
                          "with what's happening in your area",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  const SizedBox(height: 45),



                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Your Location',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),


                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        context.read<LocationBloc>().add(
                          SearchLocationEvent(
                            query: value,
                          ),
                        );

                        setState(() {});
                      },

                      decoration: InputDecoration(
                        hintText:
                        'Search city, area or address',

                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                        ),

                        suffixIcon: const Icon(
                          Icons.search,
                        ),

                        border:
                        const UnderlineInputBorder(),

                        focusedBorder:
                        const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF53B175),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),


                  if (state.status ==
                      LocationStatus.loading)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child:
                      CircularProgressIndicator(),
                    ),


                  if (searchController.text.trim().isNotEmpty &&
                      state.locations.isNotEmpty)
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: Container(
                        decoration:
                        BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics:
                          const NeverScrollableScrollPhysics(),

                          itemCount:
                          state.locations.length,

                          itemBuilder:
                              (context, index) {

                            final location =
                            state.locations[index];

                            return ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                color:
                                Color(0xFF53B175),
                              ),

                              title: Text(
                                location,
                              ),

                              onTap: () {
                                context.read<LocationBloc>().add(
                                  SelectLocationEvent(
                                    location: location,
                                  ),
                                );

                                searchController.clear();

                                setState(() {});
                              },
                            );
                          },
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),


                  if (state.selectedLocation != null)
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.all(15),

                        decoration:
                        BoxDecoration(
                          color:
                          const Color(0xFFF1F8F4),
                          borderRadius:
                          BorderRadius.circular(10),
                        ),

                        child: Row(
                          children: [

                            const Icon(
                              Icons.check_circle,
                              color:
                              Color(0xFF53B175),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                state.selectedLocation!,
                                style:
                                const TextStyle(
                                  fontWeight:
                                  FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 45),



                  Padding(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,

                      child: ElevatedButton(
                        onPressed: () {

                          context
                              .read<LocationBloc>()
                              .add(
                            const SubmitLocationEvent(),
                          );
                        },

                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF53B175),

                          foregroundColor:
                          Colors.white,

                          elevation: 0,

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),

                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}