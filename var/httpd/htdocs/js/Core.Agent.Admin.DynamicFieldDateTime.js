// --
// Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};
Core.Agent.Admin = Core.Agent.Admin || {};

/**
 * @namespace Core.Agent.Admin.DynamicFieldDateTime
 * @memberof Core.Agent.Admin
 * @author OTRS AG
 * @description
 *      This namespace contains the special module functions for the DynamicFieldDateTime module.
 */
Core.Agent.Admin.DynamicFieldDateTime = (function (TargetNS) {

    /**
     * @name ToggleYearsPeriod
     * @memberof Core.Agent.Admin.DynamicFieldDateTime
     * @function
     * @returns {Boolean} false
     * @param {Number} YearsPeriod - 0 or 1 to show or hide the Years in Future and in Past fields.
     * @description
     *      This function shows or hide two fields (Years In future and Years in Past) depending
     *      on the YearsPeriod parameter
     */
    TargetNS.ToggleYearsPeriod = function (YearsPeriod) {
        if (YearsPeriod === '1') {
            $('#YearsPeriodOption').removeClass('Hidden');
        }
        else {
            $('#YearsPeriodOption').addClass('Hidden');
        }
        return false;
    };

    /**
     * @name Init
     * @memberof Core.Agent.Admin.DynamicFieldDateTime
     * @function
     * @description
     *       Initialize module functionality
     */
    TargetNS.Init = function () {
        $('.ShowWarning').bind('change keyup', function () {
            $('p.Warning').removeClass('Hidden');
        });

        $('#YearsPeriod').bind('change', function () {
            TargetNS.ToggleYearsPeriod($(this).val());
        });

        Core.Agent.Admin.DynamicField.ValidationInit();
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.DynamicFieldDateTime || {}));
