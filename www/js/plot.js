/* 
 * plot.js
 * Main JavaScript code
 */

/* global variables */
var nEvents = 2000;
var selEvents = new Array(nEvents);
var selCount = 0;
var resetZoom = true;
var chart = null;

/* options for scatter plot */
var optionsScatter = {
    chart: {
        renderTo: "chart",
        type: "scatter",
        zoomType: "xy",
        resetZoomButton: {
            position: {
                align: "right",
                verticalAlign: "top"
            }
        },
        events: {
            selection: function(event) {
                event.preventDefault();
                /* if CTRL key is pressed, user is selecting points */
                try {
                    if (event.originalEvent.ctrlKey         /* ctrl key */
                        || event.originalEvent.metaKey) {   /* command key */
                        for (var i = 0; i < this.series[0].data.length; ++i) {
                            var point = this.series[0].data[i];
                            if (point.x > event.xAxis[0].min
                                && point.x < event.xAxis[0].max
                                && point.y > event.yAxis[0].min
                                && point.y < event.yAxis[0].max) {
                                point.select(true, true);
                            }
                        }
                    }
                    /* else, user is zooming */
                    else
                    {
                        this.xAxis[0].setExtremes(event.xAxis[0].min,
                                                  event.xAxis[0].max);
                        this.yAxis[0].setExtremes(event.yAxis[0].min,
                                                  event.yAxis[0].max);
                        if (resetZoom) {
                            /* the 'restZoom' flag is required because
                               showing and hiding the button doesn't seem to
                               work with multiple levels of zooming */
                            this.showResetZoom();
                            resetZoom = false;
                        }
                    }
                } catch (exception) {
                    /* kludgy way to make reset zoom work */
                    if (exception.message.indexOf("ctrlKey") > -1) {
                        this.xAxis[0].setExtremes(null, null);
                        this.yAxis[0].setExtremes(null, null);
                        if (!resetZoom) {
                            this.resetZoomButton.hide();
                            resetZoom = true;
                        }
                    }
                }
                return false;
            },
            click: function(event) {
                /* deselect all points if clicked on background */
                for (var i = 0; i < selCount; ++i) {
                    this.series[0].data[selEvents[i]].select(false, false);
                }
                selCount = 0;
                return;
            }
        }
    },
    title: {
        text: ""
    },
    xAxis: {
        title: {
            text: "MJD"
        },
        startOnTick: false,
        endOnTick: false,
        showLastLabel: true
    },
    yAxis: {
        title: {
            text: "DM"
        },
        startOnTick: false,
        endOnTick: false,
        showLastLabel: true
    },
    plotOptions: {
        scatter: {
            allowPointSelect: true,
            marker: {
                symbol: "circle",
                radius: 4
            },
            color: "#006600"
        },
        series: {
            name: "Data",
            point: {
                events: {
                    mouseOver: function() {
                        $("#tooltip").html(
                            /* TODO: add parameter names */
                            this.x.toFixed(2) + ", " + this.y.toFixed(2));
                    },
                    mouseOut: function() {
                        $("#tooltip").html("&nbsp;");
                    },
                    select: function(event) {
                        //console.log(this.series.data.indexOf(this));
                        selEvents[selCount++] = this.eventIdx;
                    }
                }
            }
        }
    },
    tooltip: {
        enabled: false,
        crosshairs: [true, true]
        /*useHTML: true,
        formatter: function() {
            return "<b>" + dm["6"][this.point.eventIdx] + "</b><br />"
                   + this.x.toFixed(2) + ", " + this.y.toFixed(2);
        }*/
    }
};

/* main plotting function */
function plot() {
    if (!$("#chart").is(":empty")) {        /* replot */
        $("#chart").highcharts().destroy();
    }

    /* query checkboxes and get selected data */
    var retSel = getSelectedData();
    if (-1 == retSel.retVal) {
        return;
    }

    chart = new Highcharts.Chart(optionsScatter);
    chart.showLoading();

    /* from seaborn's colour maps */
    var colours = ["#95A5A6", "#4C72B0", "#55A868", "#C44E52", "#8172B2",
                   "#CCB974", "#64B5CD"];
    var numPoints = 0;
    for (var i = 0; i < retSel.data.length; ++i) {
        var retPlot = scatterize(retSel.data[i]["mjd"], retSel.data[i]["dm"]);
        if (-1 == retPlot.retVal) {
            chart.hideLoading();
            return;
        }

        chart.addSeries({
            name: "Beam " + retSel.label[i],
            data: retPlot,
            turboThreshold: 3000,
            color: colours[parseInt(retSel.label[i])]
        });

        numPoints += retPlot[0].numPoints;
    }
    xExtremes = chart.xAxis[0].getExtremes();
    yExtremes = chart.yAxis[0].getExtremes();
    chart.xAxis[0].setExtremes(xExtremes.dataMin,
                               xExtremes.dataMax);
    chart.yAxis[0].setExtremes(yExtremes.dataMin,
                               yExtremes.dataMax);
    chart.hideLoading();
    /* set status message */
    $("#status").html(numPoints + " events in all beams.");
    /* reset selection if all pulsars plotted successfully */
    for (var i = 0; i < selCount; ++i) {
        selEvents[i] = null;
    }
    selCount = 0;

    return;
}
function getSelectedData() {
    var checkedCount = $("#params input:checked").length;
    var data = new Array();
    var label = new Array();
    var i = 0;
    $("#params input:checked").each(function() {
        if (beamData[$(this).val()] !== undefined) {
            data.push(beamData[$(this).val()]);
            label.push($(this).val());
            ++i;
        }
    });
    return {retVal: 0, data: data, label: label};
}
function scatterize(x, y) {
    var eventIdx = new Array();

    for (var i = 0; i < x.length; ++i) {
        eventIdx[i] = i;
    }

    var plotData = $.map(x, function (x, idx) {
        /* TODO: fix this - no need for retVal and numPoints in the array,
                 take them out */
        return {retVal: 0,
                numPoints: i,
                x: x,
                y: y[idx],
                eventIdx: eventIdx[idx]};
    });
    return plotData;
}
function toggleBeam(tag) {
    var series = chart.series[parseInt(tag.value)]
    if (series.visible) {
        series.hide();
    } else {
        series.show();
    }
}

