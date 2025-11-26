class scheduleRidesModel {
  bool? success;
  List<RideData>? rides;

  scheduleRidesModel({this.success, this.rides});

  scheduleRidesModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['rides'] != null) {
      rides = <RideData>[];
      json['rides'].forEach((v) {
        rides!.add(new RideData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.rides != null) {
      data['rides'] = this.rides!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class RideData {
  int? id;
  String? idUserApp;
  String? idConducteur;
  String? departName;
  String? destinationName;
  String? latitudeDepart;
  String? longitudeDepart;
  String? latitudeArrivee;
  String? longitudeArrivee;
  Null? stops;
  String? place;
  String? numberPoeple;
  String? distance;
  String? distanceUnit;
  String? duree;
  String? montant;
  Null? tipAmount;
  Null? tax;
  Null? discount;
  String? adminCommission;
  String? transactionId;
  String? trajet;
  String? statut;
  String? statutPaiement;
  String? idPaymentMethod;
  String? creer;
  String? modifier;
  Null? dateRetour;
  String? heureRetour;
  String? statutRound;
  String? statutCourse;
  String? idConducteurAccepter;
  String? tripObjective;
  String? tripCategory;
  String? ageChildren1;
  String? ageChildren2;
  String? ageChildren3;
  String? feelSafe;
  String? feelSafeDriver;
  String? carDriverConfirmed;
  Null? otp;
  Null? otpCreated;
  Null? deletedAt;
  Null? updatedAt;
  Null? dispatcherId;
  String? rideType;
  Null? userInfo;
  Null? rejectedDriverId;
  String? pickupDate;
  String? pickupTime;
  Null? type;

  RideData(
      {this.id,
        this.idUserApp,
        this.idConducteur,
        this.departName,
        this.destinationName,
        this.latitudeDepart,
        this.longitudeDepart,
        this.latitudeArrivee,
        this.longitudeArrivee,
        this.stops,
        this.place,
        this.numberPoeple,
        this.distance,
        this.distanceUnit,
        this.duree,
        this.montant,
        this.tipAmount,
        this.tax,
        this.discount,
        this.adminCommission,
        this.transactionId,
        this.trajet,
        this.statut,
        this.statutPaiement,
        this.idPaymentMethod,
        this.creer,
        this.modifier,
        this.dateRetour,
        this.heureRetour,
        this.statutRound,
        this.statutCourse,
        this.idConducteurAccepter,
        this.tripObjective,
        this.tripCategory,
        this.ageChildren1,
        this.ageChildren2,
        this.ageChildren3,
        this.feelSafe,
        this.feelSafeDriver,
        this.carDriverConfirmed,
        this.otp,
        this.otpCreated,
        this.deletedAt,
        this.updatedAt,
        this.dispatcherId,
        this.rideType,
        this.userInfo,
        this.rejectedDriverId,
        this.pickupDate,
        this.pickupTime,
        this.type});

  RideData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    idUserApp = json['id_user_app'];
    idConducteur = json['id_conducteur'];
    departName = json['depart_name'];
    destinationName = json['destination_name'];
    latitudeDepart = json['latitude_depart'];
    longitudeDepart = json['longitude_depart'];
    latitudeArrivee = json['latitude_arrivee'];
    longitudeArrivee = json['longitude_arrivee'];
    stops = json['stops'];
    place = json['place'];
    numberPoeple = json['number_poeple'];
    distance = json['distance'];
    distanceUnit = json['distance_unit'];
    duree = json['duree'];
    montant = json['montant'];
    tipAmount = json['tip_amount'];
    tax = json['tax'];
    discount = json['discount'];
    adminCommission = json['admin_commission'];
    transactionId = json['transaction_id'];
    trajet = json['trajet'];
    statut = json['statut'];
    statutPaiement = json['statut_paiement'];
    idPaymentMethod = json['id_payment_method'];
    creer = json['creer'];
    modifier = json['modifier'];
    dateRetour = json['date_retour'];
    heureRetour = json['heure_retour'];
    statutRound = json['statut_round'];
    statutCourse = json['statut_course'];
    idConducteurAccepter = json['id_conducteur_accepter'];
    tripObjective = json['trip_objective'];
    tripCategory = json['trip_category'];
    ageChildren1 = json['age_children1'];
    ageChildren2 = json['age_children2'];
    ageChildren3 = json['age_children3'];
    feelSafe = json['feel_safe'];
    feelSafeDriver = json['feel_safe_driver'];
    carDriverConfirmed = json['car_driver_confirmed'];
    otp = json['otp'];
    otpCreated = json['otp_created'];
    deletedAt = json['deleted_at'];
    updatedAt = json['updated_at'];
    dispatcherId = json['dispatcher_id'];
    rideType = json['ride_type'];
    userInfo = json['user_info'];
    rejectedDriverId = json['rejected_driver_id'];
    pickupDate = json['pickup_date'];
    pickupTime = json['pickup_time'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['id_user_app'] = this.idUserApp;
    data['id_conducteur'] = this.idConducteur;
    data['depart_name'] = this.departName;
    data['destination_name'] = this.destinationName;
    data['latitude_depart'] = this.latitudeDepart;
    data['longitude_depart'] = this.longitudeDepart;
    data['latitude_arrivee'] = this.latitudeArrivee;
    data['longitude_arrivee'] = this.longitudeArrivee;
    data['stops'] = this.stops;
    data['place'] = this.place;
    data['number_poeple'] = this.numberPoeple;
    data['distance'] = this.distance;
    data['distance_unit'] = this.distanceUnit;
    data['duree'] = this.duree;
    data['montant'] = this.montant;
    data['tip_amount'] = this.tipAmount;
    data['tax'] = this.tax;
    data['discount'] = this.discount;
    data['admin_commission'] = this.adminCommission;
    data['transaction_id'] = this.transactionId;
    data['trajet'] = this.trajet;
    data['statut'] = this.statut;
    data['statut_paiement'] = this.statutPaiement;
    data['id_payment_method'] = this.idPaymentMethod;
    data['creer'] = this.creer;
    data['modifier'] = this.modifier;
    data['date_retour'] = this.dateRetour;
    data['heure_retour'] = this.heureRetour;
    data['statut_round'] = this.statutRound;
    data['statut_course'] = this.statutCourse;
    data['id_conducteur_accepter'] = this.idConducteurAccepter;
    data['trip_objective'] = this.tripObjective;
    data['trip_category'] = this.tripCategory;
    data['age_children1'] = this.ageChildren1;
    data['age_children2'] = this.ageChildren2;
    data['age_children3'] = this.ageChildren3;
    data['feel_safe'] = this.feelSafe;
    data['feel_safe_driver'] = this.feelSafeDriver;
    data['car_driver_confirmed'] = this.carDriverConfirmed;
    data['otp'] = this.otp;
    data['otp_created'] = this.otpCreated;
    data['deleted_at'] = this.deletedAt;
    data['updated_at'] = this.updatedAt;
    data['dispatcher_id'] = this.dispatcherId;
    data['ride_type'] = this.rideType;
    data['user_info'] = this.userInfo;
    data['rejected_driver_id'] = this.rejectedDriverId;
    data['pickup_date'] = this.pickupDate;
    data['pickup_time'] = this.pickupTime;
    data['type'] = this.type;
    return data;
  }

  DateTime? get scheduleDateTime {
    if (pickupDate == null || pickupTime == null) return null;
    try {
      final dateParts = pickupDate!.split('-'); // yyyy-MM-dd
      final timeParts = pickupTime!.split(':'); // HH:mm
      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (e) {
      return null;
    }
  }
}