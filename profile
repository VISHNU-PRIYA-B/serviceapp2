// @ts-nocheck
import React, {useEffect,useState,useLayoutEffect,useContext,useCallback,} from "react";
import {View,Text,Image,StyleSheet,ActivityIndicator,TouchableOpacity,ScrollView,TextInput,Alert,Animated,} from "react-native";
import * as ImagePicker from "expo-image-picker";
import { Menu } from "react-native-paper";
import { graphqlRequest } from "../services/api";
import { useLogout } from "../hooks/Logout";
import {useNavigation,useFocusEffect,} from "@react-navigation/native";
import { UserContext } from "../components/ui/UserContext";
import { LinearGradient } from 'expo-linear-gradient';

const QUERY = `
  query {
    currentUser {
      id
      name
      companyName
      profilePic
      admin
      customer
    }
    companyProfile {
      ownerName
      companyName
      phone
      address
    }
  }
`;

const UPDATE_PROFILE_PIC = `
  mutation UpdateProfilePic($profilePic: String!) {
    updateProfile(profilePic: $profilePic) {
      success
      message
      user {
        id
        profilePic
      }
    }
  }
`;

const SAVE_COMPANY = `
  mutation SaveCompany(
    $ownerName: String!
    $companyName: String!
    $phone: String!
    $address: String!
  ) {
    createOrUpdateCompanyProfile(
      ownerName: $ownerName
      companyName: $companyName
      phone: $phone
      address: $address
    ) {
      success
      message
      companyProfile {
        ownerName
        companyName
        phone
        address
      }
    }
  }
`;
export default function Profile() {
  const { token } = useContext(UserContext);
  const navigation = useNavigation();
  const logout = useLogout();

  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [menuVisible, setMenuVisible] = useState(false);
  const [editMode, setEditMode] = useState(false);

  const [data, setData] = useState(null);
  const [profilePic, setProfilePic] = useState("");

  const [ownerName, setOwnerName] = useState("");
  const [companyName, setCompanyName] = useState("");
  const [phone, setPhone] = useState("");
  const [address, setAddress] = useState("");

  const scaleAnim = new Animated.Value(1);

  useFocusEffect(
    useCallback(() => {
      return () => {
        setMenuVisible(false);
      };
    }, [])
  );

  useEffect(() => {
    loadProfile();
  }, []);

  const loadProfile = async () => {
    try {
      const res = await graphqlRequest(QUERY, {}, token);
      setData(res);

      setProfilePic(res.currentUser?.profilePic || "");
      setOwnerName(res.currentUser?.name || "");
      setCompanyName(res.currentUser?.companyName || "");

      if (res.companyProfile) {
        setPhone(res.companyProfile.phone || "");
        setAddress(res.companyProfile.address || "");
      }
    } catch (e) {
      console.log(e);
    } finally {
      setLoading(false);
    }
  };

  const companyProfile = data?.companyProfile;
  const isAdmin = data?.currentUser?.admin;

  useLayoutEffect(() => {
    navigation.setOptions({
      title: "Profile",
      headerStyle: {
        backgroundColor: '#8B5CF6',
        elevation: 0,
        shadowOpacity: 0,
      },
      headerTintColor: '#fff',
      headerTitleStyle: {
        fontWeight: '700',
        fontSize: 22,
      },
      headerRight: () => (
        <Menu
          visible={menuVisible}
          onDismiss={() => setMenuVisible(false)}
          contentStyle={styles.menuContent}
          anchor={
            <TouchableOpacity
              onPress={() => setMenuVisible(v => !v)}
              style={styles.menuButton}
            >
              <View style={styles.menuIconContainer}>
                <View style={[styles.menuLine, menuVisible && styles.menuLineActive]} />
                <View style={[styles.menuLine, menuVisible && styles.menuLineActive]} />
                <View style={[styles.menuLine, menuVisible && styles.menuLineActive]} />
              </View>
            </TouchableOpacity>
          }
        >
          <Menu.Item
            title={companyProfile ? "Edit Company Info" : "Create Company Info"}
            titleStyle={styles.menuItemText}
            leadingIcon="pencil"
            onPress={() => {
              setMenuVisible(false);
              setEditMode(true);
            }}
          />
          <Menu.Item
            title="Logout"
            titleStyle={styles.logoutText}
            leadingIcon="logout"
            onPress={() => {
              setMenuVisible(false);
              logout();
            }}
          />
        </Menu>
      ),
    });
  }, [menuVisible, companyProfile]);

  const pickImage = async () => {
    const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) {
      Alert.alert("Permission required");
      return;
    }

    const result = await ImagePicker.launchImageLibraryAsync({
      allowsEditing: true,
      quality: 0.8,
      base64: true,
    });

    if (!result.canceled) {
      const base64Image = `data:image/jpeg;base64,${result.assets[0].base64}`;

      try {
        setUploading(true);
        const res = await graphqlRequest(
          UPDATE_PROFILE_PIC,
          { profilePic: base64Image },
          token
        );

        if (res.updateProfile.success) {
          setProfilePic(res.updateProfile.user.profilePic);
          Alert.alert("Success", "Profile picture updated");
        } else {
          Alert.alert("Error", res.updateProfile.message);
        }
      } catch {
        Alert.alert("Error", "Failed to upload image");
      } finally {
        setUploading(false);
      }
    }
  };

  const saveCompany = async () => {
    if (!ownerName || !companyName || !phone || !address) {
      Alert.alert("All fields required");
      return;
    }

    try {
      const res = await graphqlRequest(
        SAVE_COMPANY,
        { ownerName, companyName, phone, address },
        token
      );

      if (res.createOrUpdateCompanyProfile.success) {
        Alert.alert("Success", "Company details saved");
        setEditMode(false);
        loadProfile();
      } else {
        Alert.alert("Error", res.createOrUpdateCompanyProfile.message);
      }
    } catch {
      Alert.alert("Error", "Failed to save company details");
    }
  };

  if (loading) {
    return (
      <LinearGradient
        colors={['#8B5CF6', '#A78BFA', '#C4B5FD']}
        style={styles.center}
      >
        <ActivityIndicator size="large" color="#fff" />
      </LinearGradient>
    );
  }

  return (
    <View style={{ flex: 1, backgroundColor: '#F3F4F6' }}>
      <ScrollView 
        contentContainerStyle={{ paddingBottom: 120 }}
        showsVerticalScrollIndicator={false}
      >
        {/* Header Background with Gradient */}
        <LinearGradient
          colors={['#8B5CF6', '#A78BFA']}
          style={styles.headerBackground}
        >
          <View style={styles.headerContent}>
            <Text style={styles.headerTitle}>My Profile</Text>
            <Text style={styles.headerSubtitle}>Manage your account</Text>
          </View>
        </LinearGradient>

        {/* Main Card */}
        <View style={styles.card}>
          {/* Profile Picture */}
          <TouchableOpacity 
            onPress={pickImage} 
            activeOpacity={0.8}
            style={styles.avatarWrapper}
          >
            <View style={styles.avatarContainer}>
              <Image
                source={
                  profilePic
                    ? { uri: profilePic }
                    : require("../assets/images/default-avatar.png")
                }
                style={styles.avatar}
              />
              <LinearGradient
                colors={['#8B5CF6', '#A78BFA']}
                style={styles.cameraButton}
              >
                {uploading ? (
                  <ActivityIndicator size="small" color="#fff" />
                ) : (
                  <Text style={styles.cameraIcon}>📷</Text>
                )}
              </LinearGradient>
            </View>
          </TouchableOpacity>

          <Text style={styles.tapText}>Tap to change profile picture</Text>

          {/* View Mode */}
          {isAdmin && !editMode && (
            <View style={styles.infoContainer}>
              <View style={styles.infoCard}>
                <Text style={styles.ownerName}>{ownerName}</Text>
                <Text style={styles.companyName}>{companyName}</Text>
                
                {!!phone && (
                  <View style={styles.infoRow}>
                    <View style={styles.iconCircle}>
                      <Text style={styles.infoIcon}>📱</Text>
                    </View>
                    <Text style={styles.infoText}>{phone}</Text>
                  </View>
                )}
                
                {!!address && (
                  <View style={styles.infoRow}>
                    <View style={styles.iconCircle}>
                      <Text style={styles.infoIcon}>📍</Text>
                    </View>
                    <Text style={styles.infoText}>{address}</Text>
                  </View>
                )}
              </View>
            </View>
          )}

          {/* Edit Mode */}
          {isAdmin && editMode && (
            <View style={styles.editContainer}>
              <Text style={styles.editTitle}>Edit Company Information</Text>
              
              <View style={styles.inputContainer}>
                <Text style={styles.inputLabel}>Owner Name</Text>
                <TextInput 
                  style={styles.input} 
                  placeholder="Enter owner name" 
                  placeholderTextColor="#9CA3AF"
                  value={ownerName} 
                  onChangeText={setOwnerName} 
                />
              </View>

              <View style={styles.inputContainer}>
                <Text style={styles.inputLabel}>Company Name</Text>
                <TextInput 
                  style={styles.input} 
                  placeholder="Enter company name" 
                  placeholderTextColor="#9CA3AF"
                  value={companyName} 
                  onChangeText={setCompanyName} 
                />
              </View>

              <View style={styles.inputContainer}>
                <Text style={styles.inputLabel}>Phone</Text>
                <TextInput 
                  style={styles.input} 
                  placeholder="Enter phone number" 
                  placeholderTextColor="#9CA3AF"
                  keyboardType="phone-pad"
                  value={phone} 
                  onChangeText={setPhone} 
                />
              </View>

              <View style={styles.inputContainer}>
                <Text style={styles.inputLabel}>Address</Text>
                <TextInput 
                  style={[styles.input, styles.textArea]} 
                  placeholder="Enter address" 
                  placeholderTextColor="#9CA3AF"
                  multiline
                  numberOfLines={3}
                  value={address} 
                  onChangeText={setAddress} 
                />
              </View>

              <View style={styles.buttonRow}>
                <TouchableOpacity 
                  style={styles.saveBtn} 
                  onPress={saveCompany}
                  activeOpacity={0.8}
                >
                  <LinearGradient
                    colors={['#8B5CF6', '#A78BFA']}
                    style={styles.gradientButton}
                  >
                    <Text style={styles.buttonText}>Save Changes</Text>
                  </LinearGradient>
                </TouchableOpacity>

                <TouchableOpacity 
                  style={styles.cancelBtn} 
                  onPress={() => setEditMode(false)}
                  activeOpacity={0.8}
                >
                  <Text style={styles.cancelButtonText}>Cancel</Text>
                </TouchableOpacity>
              </View>
            </View>
          )}
        </View>
      </ScrollView>

      {/* ===== MODERN BOTTOM NAV ===== */}
      <View style={styles.bottomBar}>
        <TouchableOpacity 
          style={styles.bottomBtn} 
          onPress={() => navigation.navigate("CreateRepairRequest")}
          activeOpacity={0.7}
        >
          <LinearGradient
            colors={['#8B5CF6', '#A78BFA']}
            style={styles.bottomIconContainer}
          >
            <Text style={styles.bottomIcon}>➕</Text>
          </LinearGradient>
          <Text style={styles.bottomText}>Create</Text>
        </TouchableOpacity>

        <TouchableOpacity 
          style={styles.bottomBtn} 
          onPress={() => navigation.navigate("ViewRequest")}
          activeOpacity={0.7}
        >
          <LinearGradient
            colors={['#8B5CF6', '#A78BFA']}
            style={styles.bottomIconContainer}
          >
            <Text style={styles.bottomIcon}>📋</Text>
          </LinearGradient>
          <Text style={styles.bottomText}>View</Text>
        </TouchableOpacity>

        <TouchableOpacity 
          style={styles.bottomBtn} 
          onPress={() => navigation.navigate("ApproveEstimation")}
          activeOpacity={0.7}
        >
          <LinearGradient
            colors={['#8B5CF6', '#A78BFA']}
            style={styles.bottomIconContainer}
          >
            <Text style={styles.bottomIcon}>✅</Text>
          </LinearGradient>
          <Text style={styles.bottomText}>Approve</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  center: { 
    flex: 1, 
    justifyContent: "center", 
    alignItems: "center" 
  },

  headerBackground: {
    height: 180,
    borderBottomLeftRadius: 32,
    borderBottomRightRadius: 32,
    paddingHorizontal: 24,
    paddingTop: 20,
  },

  headerContent: {
    marginTop: 20,
  },

  headerTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: '#fff',
    marginBottom: 4,
  },

  headerSubtitle: {
    fontSize: 15,
    color: 'rgba(255, 255, 255, 0.8)',
  },

  card: {
    backgroundColor: "#fff",
    marginHorizontal: 20,
    marginTop: -60,
    borderRadius: 28,
    padding: 28,
    alignItems: "center",
    shadowColor: "#8B5CF6",
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.15,
    shadowRadius: 16,
    elevation: 10,
  },

  avatarWrapper: {
    marginTop: -50,
  },

  avatarContainer: {
    position: 'relative',
  },

  avatar: {
    width: 140,
    height: 140,
    borderRadius: 70,
    borderWidth: 5,
    borderColor: "#fff",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 8,
  },

  cameraButton: {
    position: 'absolute',
    bottom: 4,
    right: 4,
    width: 44,
    height: 44,
    borderRadius: 22,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 3,
    borderColor: '#fff',
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 5,
  },

  cameraIcon: {
    fontSize: 20,
  },

  tapText: { 
    color: "#5d3fa3ff", 
    marginTop: 16,
    fontSize: 14,
    fontWeight: '500',
  },

  infoContainer: {
    marginTop: 28,
    width: '100%',
  },

  infoCard: {
    backgroundColor: '#F9FAFB',
    borderRadius: 20,
    padding: 24,
    alignItems: 'center',
  },

  ownerName: { 
    fontSize: 22, 
    fontWeight: "700",
    color: '#1F2937',
    marginBottom: 6,
  },

  companyName: { 
    fontSize: 17, 
    fontWeight: "600",
    color: '#6B7280',
    marginBottom: 20,
  },

  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 12,
    backgroundColor: '#fff',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 14,
    width: '100%',
  },

  iconCircle: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#F3E8FF',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },

  infoIcon: {
    fontSize: 18,
  },

  infoText: {
    fontSize: 15,
    color: '#374151',
    flex: 1,
  },

  editContainer: {
    width: "100%",
    marginTop: 24,
  },

  editTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1F2937',
    marginBottom: 20,
    textAlign: 'center',
  },

  inputContainer: {
    marginBottom: 16,
  },

  inputLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#374151',
    marginBottom: 8,
    marginLeft: 4,
  },

  input: {
    borderWidth: 2,
    borderColor: "#E5E7EB",
    padding: 16,
    borderRadius: 16,
    fontSize: 15,
    backgroundColor: '#F9FAFB',
    color: '#1F2937',
  },

  textArea: {
    height: 90,
    textAlignVertical: 'top',
  },

  buttonRow: {
    marginTop: 8,
    gap: 12,
  },

  saveBtn: {
    borderRadius: 16,
    overflow: 'hidden',
    marginBottom: 12,
  },

  gradientButton: {
    padding: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },

  buttonText: {
    color: "#fff",
    fontWeight: '700',
    fontSize: 16,
  },

  cancelBtn: {
    backgroundColor: "#F3F4F6",
    padding: 18,
    borderRadius: 16,
    alignItems: "center",
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: '#E5E7EB',
  },

  cancelButtonText: {
    color: "#6B7280",
    fontWeight: '600',
    fontSize: 16,
  },

  bottomBar: {
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    height: 90,
    flexDirection: "row",
    backgroundColor: "#fff",
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    paddingTop: 12,
    paddingBottom: 8,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: -4 },
    shadowOpacity: 0.1,
    shadowRadius: 12,
    elevation: 20,
  },

  bottomBtn: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },

  bottomIconContainer: {
    width: 56,
    height: 56,
    borderRadius: 28,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: "#8B5CF6",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 6,
  },

  bottomIcon: {
    fontSize: 24,
  },

  bottomText: {
    color: "#6B7280",
    fontSize: 12,
    fontWeight: "600",
    marginTop: 6,
  },

  menuButton: {
    marginRight: 12,
  },

  menuIconContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 10,
  },

  menuLine: {
    width: 20,
    height: 2,
    backgroundColor: '#fff',
    marginVertical: 2,
    borderRadius: 1,
  },

  menuLineActive: {
    backgroundColor: '#fff',
  },

  menuContent: {
    backgroundColor: '#fff',
    borderRadius: 16,
    marginTop: 8,
  },

  menuItemText: {
    fontSize: 15,
    fontWeight: '500',
  },

  logoutText: {
    color: "#EF4444",
    fontSize: 15,
    fontWeight: '500',
  },
});
