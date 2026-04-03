#!/usr/bin/env python3
"""
Generate ios/Drift.xcodeproj/project.pbxproj (deterministic, no XcodeGen required).

Usage (from repository root):
  python ios/tools/generate_pbxproj.py
"""
from __future__ import annotations

import hashlib
import os
import sys


def rid(key: str) -> str:
    return hashlib.sha256(key.encode("utf-8")).hexdigest()[:24].upper()


def collect_swift_files(root_dir: str) -> list[str]:
    out: list[str] = []
    for dirpath, _, filenames in os.walk(root_dir):
        for fn in sorted(filenames):
            if fn.endswith(".swift"):
                out.append(os.path.relpath(os.path.join(dirpath, fn), os.path.dirname(root_dir)).replace("\\", "/"))
    return sorted(out)


class Tree:
    __slots__ = ("name", "children", "files")

    def __init__(self, name: str) -> None:
        self.name = name
        self.children: dict[str, Tree] = {}
        self.files: list[str] = []


def insert_file(tree: Tree, rel_path: str) -> None:
    parts = rel_path.split("/")
    node = tree
    for seg in parts[:-1]:
        node = node.children.setdefault(seg, Tree(seg))
    node.files.append(parts[-1])


def assign_group_ids(tree: Tree, prefix: str, out: dict[Tree, str]) -> None:
    key = f"{prefix}/{tree.name}" if prefix else tree.name
    out[tree] = rid(f"group:{key}")
    for ch in sorted(tree.children.values(), key=lambda x: x.name):
        assign_group_ids(ch, key, out)


def main() -> None:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    ios_dir = os.path.dirname(script_dir)
    drift_root = os.path.join(ios_dir, "Drift")
    watch_root = os.path.join(ios_dir, "Drift Watch App")

    ios_paths_rel = collect_swift_files(drift_root)
    watch_paths_rel = collect_swift_files(watch_root)

    ios_tree = Tree("Drift")
    for p in ios_paths_rel:
        insert_file(ios_tree, p[len("Drift/") :] if p.startswith("Drift/") else p)

    watch_tree = Tree("Drift Watch App")
    for p in watch_paths_rel:
        insert_file(watch_tree, p[len("Drift Watch App/") :] if p.startswith("Drift Watch App/") else p)

    group_id: dict[Tree, str] = {}
    assign_group_ids(ios_tree, "", group_id)
    assign_group_ids(watch_tree, "", group_id)

    PROJECT = rid("PBXProject")
    MAIN_GROUP = rid("mainGroup")
    PRODUCTS = rid("productsGroup")
    IOS_TARGET = rid("target.Drift")
    WATCH_TARGET = rid("target.Watch")
    IOS_PRODUCT = rid("product.Drift.app")
    WATCH_PRODUCT = rid("product.Watch.app")
    IOS_SOURCES = rid("phase.iOS.sources")
    IOS_FW = rid("phase.iOS.fw")
    IOS_RES = rid("phase.iOS.res")
    WATCH_SOURCES = rid("phase.watch.sources")
    WATCH_FW = rid("phase.watch.fw")
    EMBED_WATCH = rid("phase.embedWatch")
    IOS_CONF_LIST = rid("xc.iOS")
    WATCH_CONF_LIST = rid("xc.watch")
    PROJ_CONF_LIST = rid("xc.project")
    DEP = rid("targetDep")
    PROXY = rid("containerProxy")

    assets_ref = rid("fileref.Assets")
    strings_ref = rid("fileref.xcstrings")
    bf_assets = rid("bf.Assets")
    bf_strings = rid("bf.xcstrings")
    embed_bf = rid("bf.embed")

    ios_fw = [
        "Charts",
        "FamilyControls",
        "ManagedSettings",
        "HealthKit",
        "WatchConnectivity",
        "UserNotifications",
        "AuthenticationServices",
    ]
    watch_fw = ["WatchConnectivity", "HealthKit"]

    def fw_ref(n: str) -> str:
        return rid(f"fileref.framework.{n}")

    def fw_bf(n: str, tag: str) -> str:
        return rid(f"bf.framework.{n}.{tag}")

    lines: list[str] = []

    def emit_group(tree: Tree, parent_path: str) -> None:
        gid = group_id[tree]
        if parent_path:
            full_base = f"{parent_path}/{tree.name}"
        else:
            full_base = tree.name
        kids: list[str] = []
        for ch in sorted(tree.children.values(), key=lambda x: x.name):
            kids.append(group_id[ch])
        for fn in sorted(tree.files):
            rel = f"{full_base}/{fn}"
            kids.append(rid(f"fileref:{rel}"))
        if tree.name == "Drift" and parent_path == "":
            kids.append(assets_ref)
            kids.append(strings_ref)
        lines.append(f"\t\t{gid} /* {tree.name} */ = {{")
        lines.append("\t\t\tisa = PBXGroup;")
        lines.append("\t\t\tchildren = (")
        for k in kids:
            lines.append(f"\t\t\t\t{k},")
        lines.append("\t\t\t);")
        lines.append(f'\t\t\tpath = "{tree.name}";')
        lines.append('\t\t\tsourceTree = "<group>";')
        lines.append("\t\t};")
        for ch in sorted(tree.children.values(), key=lambda x: x.name):
            emit_group(ch, full_base)

    # --- Build file map for sources ---
    def file_ref_key(rel_from_ios: str) -> str:
        return rid(f"fileref:{rel_from_ios}")

    ap = lines.append
    ap("// !$*UTF8*$!")
    ap("{")
    ap("\tarchiveVersion = 1;")
    ap("\tclasses = {")
    ap("\t};")
    ap("\tobjectVersion = 56;")
    ap("\tobjects = {")

    ap("")
    ap("/* Begin PBXBuildFile section */")

    ios_build_swift: list[tuple[str, str]] = []
    for p in ios_paths_rel:
        rel = p.replace("\\", "/")
        bf = rid(f"bf:{rel}")
        fr = file_ref_key(rel)
        ios_build_swift.append((bf, fr))
        ap(f"\t\t{bf} /* {os.path.basename(rel)} in Sources */ = {{isa = PBXBuildFile; fileRef = {fr}; }};")

    for n in ios_fw:
        ap(f"\t\t{fw_bf(n, 'ios')} /* {n}.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {fw_ref(n)} /* {n}.framework */; }};")

    ap(f"\t\t{bf_assets} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_ref} /* Assets.xcassets */; }};")
    ap(f"\t\t{bf_strings} /* Localizable.xcstrings in Resources */ = {{isa = PBXBuildFile; fileRef = {strings_ref} /* Localizable.xcstrings */; }};")

    watch_build_swift: list[tuple[str, str]] = []
    for p in watch_paths_rel:
        rel = p.replace("\\", "/")
        bf = rid(f"bf:{rel}")
        fr = file_ref_key(rel)
        watch_build_swift.append((bf, fr))
        ap(f"\t\t{bf} /* {os.path.basename(rel)} in Sources */ = {{isa = PBXBuildFile; fileRef = {fr}; }};")

    for n in watch_fw:
        ap(f"\t\t{fw_bf(n, 'watch')} /* {n}.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {fw_ref(n)} /* {n}.framework */; }};")

    ap(
        f"\t\t{embed_bf} /* Drift Watch App.app in Embed Watch Content */ = {{isa = PBXBuildFile; fileRef = {WATCH_PRODUCT} /* Drift Watch App.app */; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};"
    )
    ap("/* End PBXBuildFile section */")

    ap("")
    ap("/* Begin PBXFileReference section */")
    ap(
        f"\t\t{IOS_PRODUCT} /* Drift.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Drift.app; sourceTree = BUILT_PRODUCTS_DIR; }};"
    )
    ap(
        f"\t\t{WATCH_PRODUCT} /* Drift Watch App.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = \"Drift Watch App.app\"; sourceTree = BUILT_PRODUCTS_DIR; }};"
    )

    def emit_file_refs(tree: Tree, parent_path: str) -> None:
        if parent_path:
            full_base = f"{parent_path}/{tree.name}"
        else:
            full_base = tree.name
        for fn in sorted(tree.files):
            rel = f"{full_base}/{fn}"
            fr = file_ref_key(rel)
            ap(
                f'\t\t{fr} /* {fn} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{fn}"; sourceTree = "<group>"; }};'
            )
        for ch in sorted(tree.children.values(), key=lambda x: x.name):
            emit_file_refs(ch, full_base)

    emit_file_refs(ios_tree, "")
    emit_file_refs(watch_tree, "")

    ap(
        f"\t\t{assets_ref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};"
    )
    ap(
        f"\t\t{strings_ref} /* Localizable.xcstrings */ = {{isa = PBXFileReference; lastKnownFileType = text.json; path = Localizable.xcstrings; sourceTree = \"<group>\"; }};"
    )

    for n in sorted(set(ios_fw + watch_fw)):
        ap(
            f"\t\t{fw_ref(n)} /* {n}.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = {n}.framework; path = System/Library/Frameworks/{n}.framework; sourceTree = SDKROOT; }};"
        )

    ap("/* End PBXFileReference section */")

    ap("")
    ap("/* Begin PBXFrameworksBuildPhase section */")
    ap(f"\t\t{IOS_FW} /* Frameworks */ = {{")
    ap("\t\t\tisa = PBXFrameworksBuildPhase;")
    ap("\t\t\tbuildActionMask = 2147483647;")
    ap("\t\t\tfiles = (")
    for n in ios_fw:
        ap(f"\t\t\t\t{fw_bf(n, 'ios')},")
    ap("\t\t\t);")
    ap("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    ap("\t\t};")
    ap(f"\t\t{WATCH_FW} /* Frameworks */ = {{")
    ap("\t\t\tisa = PBXFrameworksBuildPhase;")
    ap("\t\t\tbuildActionMask = 2147483647;")
    ap("\t\t\tfiles = (")
    for n in watch_fw:
        ap(f"\t\t\t\t{fw_bf(n, 'watch')},")
    ap("\t\t\t);")
    ap("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    ap("\t\t};")
    ap("/* End PBXFrameworksBuildPhase section */")

    ap("")
    ap("/* Begin PBXGroup section */")
    emit_group(ios_tree, "")
    emit_group(watch_tree, "")
    ap(f"\t\t{PRODUCTS} /* Products */ = {{")
    ap("\t\t\tisa = PBXGroup;")
    ap("\t\t\tchildren = (")
    ap(f"\t\t\t\t{IOS_PRODUCT},")
    ap(f"\t\t\t\t{WATCH_PRODUCT},")
    ap("\t\t\t);")
    ap("\t\t\tname = Products;")
    ap("\t\t\tsourceTree = \"<group>\";")
    ap("\t\t};")
    ap(f"\t\t{MAIN_GROUP} = {{")
    ap("\t\t\tisa = PBXGroup;")
    ap("\t\t\tchildren = (")
    ap(f"\t\t\t\t{group_id[ios_tree]},")
    ap(f"\t\t\t\t{group_id[watch_tree]},")
    ap(f"\t\t\t\t{PRODUCTS},")
    ap("\t\t\t);")
    ap("\t\t\tsourceTree = \"<group>\";")
    ap("\t\t};")
    ap("/* End PBXGroup section */")

    ap("")
    ap("/* Begin PBXNativeTarget section */")
    ap(f"\t\t{IOS_TARGET} /* Drift */ = {{")
    ap("\t\t\tisa = PBXNativeTarget;")
    ap(f"\t\t\tbuildConfigurationList = {IOS_CONF_LIST} /* Build configuration list for PBXNativeTarget \"Drift\" */;")
    ap("\t\t\tbuildPhases = (")
    ap(f"\t\t\t\t{IOS_SOURCES} /* Sources */,")
    ap(f"\t\t\t\t{IOS_FW} /* Frameworks */,")
    ap(f"\t\t\t\t{IOS_RES} /* Resources */,")
    ap(f"\t\t\t\t{EMBED_WATCH} /* Embed Watch Content */,")
    ap("\t\t\t);")
    ap("\t\t\tbuildRules = (")
    ap("\t\t\t);")
    ap("\t\t\tdependencies = (")
    ap(f"\t\t\t\t{DEP} /* PBXTargetDependency */,")
    ap("\t\t\t);")
    ap("\t\t\tname = Drift;")
    ap("\t\t\tproductName = Drift;")
    ap(f"\t\t\tproductReference = {IOS_PRODUCT} /* Drift.app */;")
    ap('\t\t\tproductType = "com.apple.product-type.application";')
    ap("\t\t};")
    ap(f"\t\t{WATCH_TARGET} /* Drift Watch App */ = {{")
    ap("\t\t\tisa = PBXNativeTarget;")
    ap(f"\t\t\tbuildConfigurationList = {WATCH_CONF_LIST} /* Build configuration list for PBXNativeTarget \"Drift Watch App\" */;")
    ap("\t\t\tbuildPhases = (")
    ap(f"\t\t\t\t{WATCH_SOURCES} /* Sources */,")
    ap(f"\t\t\t\t{WATCH_FW} /* Frameworks */,")
    ap("\t\t\t);")
    ap("\t\t\tbuildRules = (")
    ap("\t\t\t);")
    ap("\t\t\tdependencies = (")
    ap("\t\t\t);")
    ap("\t\t\tname = \"Drift Watch App\";")
    ap("\t\t\tproductName = \"Drift Watch App\";")
    ap(f"\t\t\tproductReference = {WATCH_PRODUCT} /* Drift Watch App.app */;")
    ap('\t\t\tproductType = "com.apple.product-type.application";')
    ap("\t\t};")
    ap("/* End PBXNativeTarget section */")

    ap("")
    ap("/* Begin PBXProject section */")
    ap(f"\t\t{PROJECT} /* Project object */ = {{")
    ap("\t\t\tisa = PBXProject;")
    ap("\t\t\tattributes = {")
    ap("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    ap("\t\t\t\tLastSwiftUpdateCheck = 1500;")
    ap("\t\t\t\tLastUpgradeCheck = 1500;")
    ap("\t\t\t\tTargetAttributes = {")
    ap(f"\t\t\t\t\t{IOS_TARGET} = {{")
    ap("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    ap("\t\t\t\t\t};")
    ap(f"\t\t\t\t\t{WATCH_TARGET} = {{")
    ap("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    ap("\t\t\t\t\t};")
    ap("\t\t\t\t};")
    ap("\t\t\t};")
    ap(f"\t\t\tbuildConfigurationList = {PROJ_CONF_LIST} /* Build configuration list for PBXProject \"Drift\" */;")
    ap('\t\t\tcompatibilityVersion = "Xcode 14.0";')
    ap("\t\t\tdevelopmentRegion = en;")
    ap("\t\t\thasScannedForEncodings = 0;")
    ap("\t\t\tknownRegions = (")
    ap("\t\t\t\ten,")
    ap("\t\t\t\tBase,")
    ap("\t\t\t);")
    ap(f"\t\t\tmainGroup = {MAIN_GROUP};")
    ap(f"\t\t\tproductRefGroup = {PRODUCTS} /* Products */;")
    ap(f"\t\t\tprojectDirPath = \"\";")
    ap("\t\t\tprojectRoot = \"\";")
    ap("\t\t\ttargets = (")
    ap(f"\t\t\t\t{IOS_TARGET} /* Drift */,")
    ap(f"\t\t\t\t{WATCH_TARGET} /* Drift Watch App */,")
    ap("\t\t\t);")
    ap("\t\t};")
    ap("/* End PBXProject section */")

    ap("")
    ap("/* Begin PBXResourcesBuildPhase section */")
    ap(f"\t\t{IOS_RES} /* Resources */ = {{")
    ap("\t\t\tisa = PBXResourcesBuildPhase;")
    ap("\t\t\tbuildActionMask = 2147483647;")
    ap("\t\t\tfiles = (")
    ap(f"\t\t\t\t{bf_assets},")
    ap(f"\t\t\t\t{bf_strings},")
    ap("\t\t\t);")
    ap("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    ap("\t\t};")
    ap("/* End PBXResourcesBuildPhase section */")

    ap("")
    ap("/* Begin PBXSourcesBuildPhase section */")
    ap(f"\t\t{IOS_SOURCES} /* Sources */ = {{")
    ap("\t\t\tisa = PBXSourcesBuildPhase;")
    ap("\t\t\tbuildActionMask = 2147483647;")
    ap("\t\t\tfiles = (")
    for bf, _ in ios_build_swift:
        ap(f"\t\t\t\t{bf},")
    ap("\t\t\t);")
    ap("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    ap("\t\t};")
    ap(f"\t\t{WATCH_SOURCES} /* Sources */ = {{")
    ap("\t\t\tisa = PBXSourcesBuildPhase;")
    ap("\t\t\tbuildActionMask = 2147483647;")
    ap("\t\t\tfiles = (")
    for bf, _ in watch_build_swift:
        ap(f"\t\t\t\t{bf},")
    ap("\t\t\t);")
    ap("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    ap("\t\t};")
    ap("/* End PBXSourcesBuildPhase section */")

    ap("")
    ap("/* Begin PBXCopyFilesBuildPhase section */")
    ap(f"\t\t{EMBED_WATCH} /* Embed Watch Content */ = {{")
    ap("\t\t\tisa = PBXCopyFilesBuildPhase;")
    ap("\t\t\tbuildActionMask = 2147483647;")
    ap('\t\t\tdstPath = "$(CONTENTS_FOLDER_PATH)/Watch";')
    ap("\t\t\tdstSubfolderSpec = 16;")
    ap("\t\t\tfiles = (")
    ap(f"\t\t\t\t{embed_bf} /* Drift Watch App.app in Embed Watch Content */,")
    ap("\t\t\t);")
    ap('\t\t\tname = "Embed Watch Content";')
    ap("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    ap("\t\t};")
    ap("/* End PBXCopyFilesBuildPhase section */")

    ap("")
    ap("/* Begin PBXContainerItemProxy section */")
    ap(f"\t\t{PROXY} /* PBXContainerItemProxy */ = {{")
    ap("\t\t\tisa = PBXContainerItemProxy;")
    ap(f"\t\t\tcontainerPortal = {PROJECT} /* Project object */;")
    ap("\t\t\tproxyType = 1;")
    ap(f"\t\t\tremoteGlobalIDString = {WATCH_TARGET};")
    ap('\t\t\tremoteInfo = "Drift Watch App";')
    ap("\t\t};")
    ap("/* End PBXContainerItemProxy section */")

    ap("")
    ap("/* Begin PBXTargetDependency section */")
    ap(f"\t\t{DEP} /* PBXTargetDependency */ = {{")
    ap("\t\t\tisa = PBXTargetDependency;")
    ap(f"\t\t\ttarget = {WATCH_TARGET} /* Drift Watch App */;")
    ap(f"\t\t\ttargetProxy = {PROXY} /* PBXContainerItemProxy */;")
    ap("\t\t};")
    ap("/* End PBXTargetDependency section */")

    # XCBuildConfiguration
    IOS_DBG = rid("xc.iOS.Debug")
    IOS_REL = rid("xc.iOS.Release")
    W_DBG = rid("xc.watch.Debug")
    W_REL = rid("xc.watch.Release")
    P_DBG = rid("xc.proj.Debug")
    P_REL = rid("xc.proj.Release")

    ap("")
    ap("/* Begin XCBuildConfiguration section */")
    ap(f"\t\t{IOS_DBG} /* Debug */ = {{")
    ap("\t\t\tisa = XCBuildConfiguration;")
    ap("\t\t\tbuildSettings = {")
    ap('\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;')
    ap("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    ap("\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
    ap("\t\t\t\tDEVELOPMENT_TEAM = \"\";")
    ap("\t\t\t\tENABLE_PREVIEWS = YES;")
    ap("\t\t\t\tGENERATE_INFOPLIST_FILE = NO;")
    ap('\t\t\t\tINFOPLIST_FILE = Drift/Info.plist;')
    ap("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;")
    ap('\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");')
    ap("\t\t\t\tMARKETING_VERSION = 1.0;")
    ap("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.drift.Drift;")
    ap('\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
    ap("\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;")
    ap("\t\t\t\tSWIFT_VERSION = 5.0;")
    ap('\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";')
    ap("\t\t\t};")
    ap("\t\t\tname = Debug;")
    ap("\t\t};")
    ap(f"\t\t{IOS_REL} /* Release */ = {{")
    ap("\t\t\tisa = XCBuildConfiguration;")
    ap("\t\t\tbuildSettings = {")
    ap('\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;')
    ap("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    ap("\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
    ap("\t\t\t\tDEVELOPMENT_TEAM = \"\";")
    ap("\t\t\t\tGENERATE_INFOPLIST_FILE = NO;")
    ap('\t\t\t\tINFOPLIST_FILE = Drift/Info.plist;')
    ap("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;")
    ap('\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");')
    ap("\t\t\t\tMARKETING_VERSION = 1.0;")
    ap("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.drift.Drift;")
    ap('\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
    ap("\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;")
    ap("\t\t\t\tSWIFT_VERSION = 5.0;")
    ap('\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";')
    ap("\t\t\t};")
    ap("\t\t\tname = Release;")
    ap("\t\t};")

    ap(f"\t\t{W_DBG} /* Debug */ = {{")
    ap("\t\t\tisa = XCBuildConfiguration;")
    ap("\t\t\tbuildSettings = {")
    ap("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    ap("\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
    ap("\t\t\t\tDEVELOPMENT_TEAM = \"\";")
    ap("\t\t\t\tGENERATE_INFOPLIST_FILE = NO;")
    ap('\t\t\t\tINFOPLIST_FILE = "Drift Watch App/Info.plist";')
    ap("\t\t\t\tMARKETING_VERSION = 1.0;")
    ap("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.drift.Drift.watchkitapp;")
    ap('\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
    ap("\t\t\t\tSDKROOT = watchos;")
    ap("\t\t\t\tSKIP_INSTALL = YES;")
    ap("\t\t\t\tSWIFT_VERSION = 5.0;")
    ap("\t\t\t\tTARGETED_DEVICE_FAMILY = 4;")
    ap("\t\t\t\tWATCHOS_DEPLOYMENT_TARGET = 10.0;")
    ap("\t\t\t};")
    ap("\t\t\tname = Debug;")
    ap("\t\t};")
    ap(f"\t\t{W_REL} /* Release */ = {{")
    ap("\t\t\tisa = XCBuildConfiguration;")
    ap("\t\t\tbuildSettings = {")
    ap("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    ap("\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
    ap("\t\t\t\tDEVELOPMENT_TEAM = \"\";")
    ap("\t\t\t\tGENERATE_INFOPLIST_FILE = NO;")
    ap('\t\t\t\tINFOPLIST_FILE = "Drift Watch App/Info.plist";')
    ap("\t\t\t\tMARKETING_VERSION = 1.0;")
    ap("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.drift.Drift.watchkitapp;")
    ap('\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
    ap("\t\t\t\tSDKROOT = watchos;")
    ap("\t\t\t\tSKIP_INSTALL = YES;")
    ap("\t\t\t\tSWIFT_VERSION = 5.0;")
    ap("\t\t\t\tTARGETED_DEVICE_FAMILY = 4;")
    ap("\t\t\t\tWATCHOS_DEPLOYMENT_TARGET = 10.0;")
    ap("\t\t\t};")
    ap("\t\t\tname = Release;")
    ap("\t\t};")

    ap(f"\t\t{P_DBG} /* Debug */ = {{")
    ap("\t\t\tisa = XCBuildConfiguration;")
    ap("\t\t\tbuildSettings = {")
    ap("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
    ap("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
    ap("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;")
    ap("\t\t\t\tCOPY_PHASE_STRIP = NO;")
    ap("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
    ap("\t\t\t\tENABLE_TESTABILITY = YES;")
    ap("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
    ap("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;")
    ap("\t\t\t\tONLY_ACTIVE_ARCH = YES;")
    ap("\t\t\t\tSDKROOT = iphoneos;")
    ap("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;")
    ap("\t\t\t\tWATCHOS_DEPLOYMENT_TARGET = 10.0;")
    ap("\t\t\t};")
    ap("\t\t\tname = Debug;")
    ap("\t\t};")
    ap(f"\t\t{P_REL} /* Release */ = {{")
    ap("\t\t\tisa = XCBuildConfiguration;")
    ap("\t\t\tbuildSettings = {")
    ap("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
    ap("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
    ap("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;")
    ap("\t\t\t\tCOPY_PHASE_STRIP = YES;")
    ap("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf-with-dsym;")
    ap("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;")
    ap("\t\t\t\tSDKROOT = iphoneos;")
    ap("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
    ap("\t\t\t\tWATCHOS_DEPLOYMENT_TARGET = 10.0;")
    ap("\t\t\t};")
    ap("\t\t\tname = Release;")
    ap("\t\t};")
    ap("/* End XCBuildConfiguration section */")

    ap("")
    ap("/* Begin XCConfigurationList section */")
    ap(f"\t\t{IOS_CONF_LIST} /* Build configuration list for PBXNativeTarget \"Drift\" */ = {{")
    ap("\t\t\tisa = XCConfigurationList;")
    ap("\t\t\tbuildConfigurations = (")
    ap(f"\t\t\t\t{IOS_DBG},")
    ap(f"\t\t\t\t{IOS_REL},")
    ap("\t\t\t);")
    ap("\t\t\tdefaultConfigurationIsVisible = 0;")
    ap("\t\t\tdefaultConfigurationName = Release;")
    ap("\t\t};")
    ap(f"\t\t{WATCH_CONF_LIST} /* Build configuration list for PBXNativeTarget \"Drift Watch App\" */ = {{")
    ap("\t\t\tisa = XCConfigurationList;")
    ap("\t\t\tbuildConfigurations = (")
    ap(f"\t\t\t\t{W_DBG},")
    ap(f"\t\t\t\t{W_REL},")
    ap("\t\t\t);")
    ap("\t\t\tdefaultConfigurationIsVisible = 0;")
    ap("\t\t\tdefaultConfigurationName = Release;")
    ap("\t\t};")
    ap(f"\t\t{PROJ_CONF_LIST} /* Build configuration list for PBXProject \"Drift\" */ = {{")
    ap("\t\t\tisa = XCConfigurationList;")
    ap("\t\t\tbuildConfigurations = (")
    ap(f"\t\t\t\t{P_DBG},")
    ap(f"\t\t\t\t{P_REL},")
    ap("\t\t\t);")
    ap("\t\t\tdefaultConfigurationIsVisible = 0;")
    ap("\t\t\tdefaultConfigurationName = Release;")
    ap("\t\t};")
    ap("/* End XCConfigurationList section */")

    ap("\t};")
    ap(f"\trootObject = {PROJECT} /* Project object */;")
    ap("}")

    out_path = os.path.join(ios_dir, "Drift.xcodeproj", "project.pbxproj")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
    sys.exit(0)
