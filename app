import "react-native-gesture-handler";
import React, { useContext, useEffect } from "react";
import { NavigationContainer } from "@react-navigation/native";
import { createNativeStackNavigator } from "@react-navigation/native-stack";
import { UserProvider, UserContext } from "./components/ui/UserContext";
import { setAuthToken } from "./services/api";
import Login from "./screens/Login";
import Signup from "./screens/Signup";
import Profile from "./screens/Profile";
import CreateRepairRequest from "./screens/CreateRepairRequest";
import AddEstimation from "./screens/AddEstimation";
import ViewRequest from "./screens/ViewRequest";
import ApproveEstimation from "./screens/ApproveEstimation";
import AdminEstimation from "./screens/AdminEstimation";
import UpdateStatus from "./screens/UpdateStatus";
import Invoice from "./screens/Invoice";

export type RootStackParamList = {
  Login: undefined;
  Signup: undefined;
  Profile: undefined;
  CreateRepairRequest: undefined;
  AddEstimation: undefined;
  ViewRequest: undefined;
  ApproveEstimation: undefined;
  AdminEstimation: undefined;
  UpdateStatus: undefined;
  Invoice: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

function AppContent() {
  const { token } = useContext(UserContext);

  
  useEffect(() => {
    if(token){
        setAuthToken(token);
    }
  }, [token]);

  return (
    <NavigationContainer>
      <Stack.Navigator initialRouteName="Login">
        <Stack.Screen
          name="Login"
          component={Login}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="Signup"
          component={Signup}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="CreateRepairRequest"
          component={CreateRepairRequest}
          options={{ title: "Repair Request" }}
        />
        <Stack.Screen
          name="Profile"
          component={Profile}
          options={{ title: "Profile" }}
        />
        <Stack.Screen
          name="AddEstimation"
          component={AddEstimation}
          options={{ title: "Add Estimation" }}
        />
        <Stack.Screen
          name="ViewRequest"
          component={ViewRequest}
          options={{ title: "View Request" }}
        />
        <Stack.Screen
          name="ApproveEstimation"
          component={ApproveEstimation}
          options={{ title: "Approve Estimation" }}
        />
          <Stack.Screen
          name="AdminEstimation"
          component={AdminEstimation}
          options={{ title: "Admin Estimation" }}
        />
        <Stack.Screen
          name="UpdateStatus"
          component={UpdateStatus}
          options={{ title: "Update Status" }}
        />
        <Stack.Screen
          name="Invoice"
          component={Invoice}
          options={{ title: "Invoice" }}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
}

export default function App() {
  return (
    <UserProvider>
      <AppContent />
    </UserProvider>
  );
}
