import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/region.dart';
import '../parser.dart';
import '../size_controller.dart';
import './region_painter.dart';

class InteractableSvg extends StatefulWidget {
  final bool _isFromWeb;
  final bool _isString;
  final double? width;
  final double? height;
  final String svgAddress;
  final String fileName;
  final Function(Region? region) onChanged;
  final Color? strokeColor;
  final double? strokeWidth;
  final Color? selectedColor;
  final Color? dotColor;
  final bool? toggleEnable;
  final String? unSelectableId;
  final bool? centerDotEnable;
  final bool? centerTextEnable;
  final bool? isMultiSelectable;
  final TextStyle? centerTextStyle;
  final String? centerIconPath;
  final int? heightCenterIconPath;
  final int? widthCenterIconPath;
  final Color? fillColor;
  final String? selectedValue;

  const InteractableSvg({
    Key? key,
    required this.svgAddress,
    required this.onChanged,
    this.width,
    this.height,
    this.strokeColor,
    this.strokeWidth,
    this.selectedColor,
    this.dotColor,
    this.unSelectableId,
    this.centerDotEnable,
    this.centerTextEnable,
    this.centerTextStyle,
    this.toggleEnable,
    this.isMultiSelectable,
    this.centerIconPath,
    this.heightCenterIconPath,
    this.widthCenterIconPath,
    this.fillColor,
    this.selectedValue,
  })  : _isFromWeb = false,
        _isString = false,
        fileName = "",
        super(key: key);

  const InteractableSvg.network({
    required this.fileName,
    Key? key,
    required this.svgAddress,
    required this.onChanged,
    this.width,
    this.height,
    this.strokeColor,
    this.strokeWidth,
    this.selectedColor,
    this.dotColor,
    this.unSelectableId,
    this.centerDotEnable,
    this.centerTextEnable,
    this.centerTextStyle,
    this.toggleEnable,
    this.isMultiSelectable,
    this.centerIconPath,
    this.heightCenterIconPath,
    this.widthCenterIconPath,
    this.fillColor,
    this.selectedValue,
  })  : _isFromWeb = true,
        _isString = false,
        super(key: key);

  const InteractableSvg.string({
    Key? key,
    required this.svgAddress,
    required this.onChanged,
    this.width,
    this.height,
    this.strokeColor,
    this.strokeWidth,
    this.selectedColor,
    this.dotColor,
    this.unSelectableId,
    this.centerDotEnable,
    this.centerTextEnable,
    this.centerTextStyle,
    this.toggleEnable,
    this.isMultiSelectable,
    this.centerIconPath,
    this.heightCenterIconPath,
    this.widthCenterIconPath,
    this.fillColor,
    this.selectedValue,
  })  : _isFromWeb = false,
        _isString = true,
        fileName = "",
        super(key: key);

  @override
  InteractableSvgState createState() => InteractableSvgState();
}

class InteractableSvgState extends State<InteractableSvg> {
  final List<Region> _regionList = [];

  List<Region> selectedRegion = [];
  String? selectedValue;

  final _sizeController = SizeController.instance;
  Size? mapSize;

  ui.Image? pinIcon;
  Future<ui.Image> getUiImage(
      String imageAssetPath, int height, int width) async {
    final ByteData assetImageByteData = await rootBundle.load(imageAssetPath);
    final codec = await ui.instantiateImageCodec(
      assetImageByteData.buffer.asUint8List(),
      targetHeight: height,
      targetWidth: width,
    );
    final image = (await codec.getNextFrame()).image;
    return image;
  }

  getImage() async {
    if (widget.centerIconPath != null) {
      pinIcon = await getUiImage(
        widget.centerIconPath!,
        widget.heightCenterIconPath ?? 40,
        widget.widthCenterIconPath ?? 40,
      );
    }
  }

  @override
  void didUpdateWidget(covariant InteractableSvg oldWidget) {
    setState(() {
      selectedValue = widget.selectedValue;
    });
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getImage();
      _loadRegionList();
    });
  }

  _loadRegionList() async {
    late final List<Region> list;
    if (widget._isFromWeb) {
      list = await Parser.instance
          .svgToRegionListNetwork(widget.svgAddress, widget.fileName);
    } else if (widget._isString) {
      list = await Parser.instance.svgToRegionListString(widget.svgAddress);
    } else {
      list = await Parser.instance.svgToRegionList(widget.svgAddress);
    }

    _regionList.clear();
    setState(() {
      _regionList.addAll(list);
      mapSize = _sizeController.mapSize;
      selectedValue = widget.selectedValue;
    });
  }

  void clearSelect() {
    setState(() {
      selectedRegion.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var region in _regionList) _buildStackItem(region),
      ],
    );
  }

  Widget _buildStackItem(Region region) {
    bool isSelect = false;
    isSelect = region.id == selectedValue;

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: () => (widget.toggleEnable ?? false)
          ? toggleButton(region)
          : holdButton(region),
      child: CustomPaint(
        isComplex: true,
        foregroundPainter: RegionPainter(
          region: region,
          isSelected: selectedRegion.contains(region) || isSelect,
          selectedRegion: selectedRegion,
          dotColor: widget.dotColor,
          selectedColor: widget.selectedColor,
          strokeColor: widget.strokeColor,
          centerDotEnable: widget.centerDotEnable,
          centerTextEnable: widget.centerTextEnable,
          centerTextStyle: widget.centerTextStyle,
          strokeWidth: widget.strokeWidth,
          unSelectableId: widget.unSelectableId,
          pinIcon: pinIcon,
          fillColor: widget.fillColor,
        ),
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? double.infinity,
          constraints: BoxConstraints(
              maxWidth: mapSize?.width ?? 0, maxHeight: mapSize?.height ?? 0),
          alignment: Alignment.center,
        ),
      ),
    );
  }

  void toggleButton(Region region) {
    selectedValue = null;
    if (region.id != widget.unSelectableId) {
      setState(() {
        if (selectedRegion.contains(region)) {
          selectedRegion.remove(region);
        } else {
          if (widget.isMultiSelectable ?? false) {
            selectedRegion.add(region);
          } else {
            selectedRegion.clear();
            selectedRegion.add(region);
          }
        }
        widget.onChanged.call(region);
      });
    }
  }

  void holdButton(Region region) {
    if (region.id != widget.unSelectableId) {
      setState(() {
        if (widget.isMultiSelectable ?? false) {
          selectedRegion.add(region);
          widget.onChanged.call(region);
        } else {
          selectedRegion.clear();
          selectedRegion.add(region);
          selectedValue = region.name;

          widget.onChanged.call(region);
        }
      });
    }
  }
}
