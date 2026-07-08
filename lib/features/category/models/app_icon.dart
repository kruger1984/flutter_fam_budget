import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:heroicons/heroicons.dart';

enum AppIcon {
  @JsonValue('heroicon-o-shopping-cart') shoppingCart(HeroIcons.shoppingCart, 'heroicon-o-shopping-cart'),

  @JsonValue('heroicon-o-briefcase') briefcase(HeroIcons.briefcase, 'heroicon-o-briefcase'),

  @JsonValue('heroicon-o-truck') truck(HeroIcons.truck, 'heroicon-o-truck'),

  @JsonValue('heroicon-o-home') home(HeroIcons.home, 'heroicon-o-home'),

  @JsonValue('heroicon-o-heart') heart(HeroIcons.heart, 'heroicon-o-heart'),

  @JsonValue('heroicon-o-squares-2x2') squares2x2(HeroIcons.squares2x2, 'heroicon-o-squares-2x2'),

  @JsonValue('heroicon-o-bolt') bolt(HeroIcons.bolt, 'heroicon-o-bolt'),

  @JsonValue('heroicon-o-academic-cap') academicCap(HeroIcons.academicCap, 'heroicon-o-academic-cap'),

  @JsonValue('heroicon-o-shopping-bag') shoppingBag(HeroIcons.shoppingBag, 'heroicon-o-shopping-bag'),

  @JsonValue('heroicon-o-building-storefront') buildingStorefront(HeroIcons.buildingStorefront, 'heroicon-o-building-storefront'),

  @JsonValue('heroicon-o-film') film(HeroIcons.film, 'heroicon-o-film'),

  @JsonValue('heroicon-o-gift') gift(HeroIcons.gift, 'heroicon-o-gift'),

  @JsonValue('heroicon-o-banknotes') banknotes(HeroIcons.banknotes, 'heroicon-o-banknotes'),

  @JsonValue('heroicon-o-credit-card') creditCard(HeroIcons.creditCard, 'heroicon-o-credit-card'),

  @JsonValue('heroicon-o-chart-bar') chartBar(HeroIcons.chartBar, 'heroicon-o-chart-bar'),

  @JsonValue('heroicon-o-paper-airplane') paperAirplane(HeroIcons.paperAirplane, 'heroicon-o-paper-airplane'),

  @JsonValue('heroicon-o-user-group') userGroup(HeroIcons.userGroup, 'heroicon-o-user-group'),

  @JsonValue('heroicon-o-trophy') trophy(HeroIcons.trophy, 'heroicon-o-trophy'),

  @JsonValue('heroicon-o-device-phone-mobile') devicePhoneMobile(HeroIcons.devicePhoneMobile, 'heroicon-o-device-phone-mobile'),

  @JsonValue('heroicon-o-receipt-percent') receiptPercent(HeroIcons.receiptPercent, 'heroicon-o-receipt-percent'),

  @JsonValue('heroicon-o-wrench-screwdriver') wrenchScrewdriver(HeroIcons.wrenchScrewdriver, 'heroicon-o-wrench-screwdriver'),

  @JsonValue('heroicon-o-sparkles') sparkles(HeroIcons.sparkles, 'heroicon-o-sparkles'),

  @JsonValue('heroicon-o-question-mark-circle') question(HeroIcons.questionMarkCircle, 'heroicon-o-question-mark-circle');


  final HeroIcons heroData;
  final String backendValue;

  const AppIcon(this.heroData, this.backendValue);
}
