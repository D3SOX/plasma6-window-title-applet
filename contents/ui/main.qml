/*
*  Copyright 2018 Michail Vourlakos <mvourlakos@gmail.com>
*
*  This file is part of applet-window-title
*
*  Latte-Dock is free software; you can redistribute it and/or
*  modify it under the terms of the GNU General Public License as
*  published by the Free Software Foundation; either version 2 of
*  the License, or (at your option) any later version.
*
*  Latte-Dock is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.7
import QtQml.Models 2.2
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.4

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.taskmanager 0.1 as TaskManager

import org.kde.activities 0.1 as Activities

Item {
    id: root
    clip: true

    Layout.fillHeight: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? true : false
    Layout.fillWidth: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? false : true

    Layout.minimumWidth: minimumWidth
    Layout.minimumHeight: minimumHeight
    Layout.preferredHeight: Layout.minimumHeight
    Layout.preferredWidth: Layout.minimumWidth
    Layout.maximumHeight: Layout.minimumHeight
    Layout.maximumWidth: Layout.minimumWidth

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
    Plasmoid.onFormFactorChanged: plasmoid.configuration.formFactor = plasmoid.formFactor;

    readonly property int minimumWidth: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? contents.width : -1;
    readonly property int minimumHeight: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? -1 : contents.height;

    readonly property bool existsWindowActive: activeTaskItem && tasksRepeater.count > 0 && activeTaskItem.isActive
    readonly property bool isActiveWindowPinned: existsWindowActive && activeTaskItem.isOnAllDesktops
    readonly property bool isActiveWindowMaximized: existsWindowActive && activeTaskItem.isMaximized

    property Item activeTaskItem: null


    //BEGIN Latte Dock Communicator
    property bool isInLatte: false  // deprecated Latte v0.8 API
    property QtObject latteBridge: null // current Latte v0.9 API

    onLatteBridgeChanged: {
        if (latteBridge) {
            latteBridge.actions.setProperty(plasmoid.id, "disableLatteSideColoring", true);
        }
    }
    //END  Latte Dock Communicator
    //BEGIN Latte based properties
    readonly property bool enforceLattePalette: latteBridge && latteBridge.applyPalette && latteBridge.palette
    readonly property bool latteInEditMode: latteBridge && latteBridge.inEditMode
    //END Latte based properties

    // START Tasks logic
    // To get current activity name
    TaskManager.ActivityInfo {
        id: activityInfo
    }

    Activities.ActivityInfo {
        id: fullActivityInfo
        activityId: activityInfo.currentActivity
    }

    // To get virtual desktop name
    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    TaskManager.TasksModel {
        id: tasksModel
        sortMode: TaskManager.TasksModel.SortVirtualDesktop
        groupMode: TaskManager.TasksModel.GroupDisabled
        screenGeometry: plasmoid.screenGeometry
        activity: activityInfo.currentActivity
        virtualDesktop: virtualDesktopInfo.currentDesktop

        filterByScreen: true
        filterByVirtualDesktop: true
        filterByActivity: true
    }

    Repeater{
        id: tasksRepeater
        model:DelegateModel {
            model: tasksModel
            delegate: Item{
                id: task
                readonly property string title: display
                readonly property string appName: AppName
                readonly property bool isMinimized: IsMinimized === true ? true : false
                readonly property bool isMaximized: IsMaximized === true ? true : false
                readonly property bool isActive: IsActive === true ? true : false
                readonly property bool isOnAllDesktops: IsOnAllVirtualDesktops === true ? true : false
                property var icon: decoration

                onIsActiveChanged: {
                    if (isActive) {
                        root.activeTaskItem = task;
                    }
                }
            }
        }
    }
    // END Tasks logic

    RowLayout{
        id: contents

        readonly property int thickness: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? root.height : root.width

        Item{
            id: firstSpacer
            Layout.minimumWidth: plasmoid.configuration.lengthFirstMargin
            Layout.preferredWidth: Layout.minimumWidth
            Layout.maximumWidth: Layout.minimumWidth
        }

        RowLayout{
            spacing: plasmoid.configuration.spacing

            PlasmaCore.IconItem{
                Layout.minimumWidth: contents.thickness
                Layout.maximumWidth: Layout.minimumWidth

                Layout.minimumHeight: contents.thickness
                Layout.maximumHeight: Layout.minimumHeight

                visible: plasmoid.configuration.showIcon
                usesPlasmaTheme: true
                source: existsWindowActive ? activeTaskItem.icon : fullActivityInfo.icon
            }

            Label{
                Layout.minimumWidth: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? -1 : contents.thickness
                Layout.maximumWidth: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? Infinity : contents.thickness

                Layout.minimumHeight: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? contents.thickness : -1
                Layout.maximumHeight: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? contents.thickness : Infinity

                verticalAlignment: Text.AlignVCenter

                text: existsWindowActive ? activeTaskItem.appName : fullActivityInfo.name
                color: enforceLattePalette ? latteBridge.palette.textColor : theme.textColor
                font.bold: true
            }
        }

        Item{
            id: lastSpacer
            Layout.minimumWidth: plasmoid.configuration.lengthLastMargin
            Layout.preferredWidth: Layout.minimumWidth
            Layout.maximumWidth: Layout.minimumWidth
        }
    }
}
