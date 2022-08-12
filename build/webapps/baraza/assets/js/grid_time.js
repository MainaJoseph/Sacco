    var MyTimeField = function(config) {
        jsGrid.Field.call(this, config);
    };

    MyTimeField.prototype = new jsGrid.Field({

        css: "time-field",               // redefine general property 'css'
        align: "center",                 // redefine general property 'align'

        myCustomProperty: "timecp",      // custom property

        sorter: function(date1, date2) {
            return new Date(date1) - new Date(date2);
        },

        itemTemplate: function(value) {
			var dt = '';
			if(value) dt = value;
            return dt;
        },

        insertTemplate: function(value) {
            return this._insertPicker = $("<input>").timepicker({ defaultDate: new Date(), minuteStep: 5 });
        },

		editTemplate: function (value) {
			this._editPicker = $("<input>").timepicker({ defaultDate: value, minuteStep: 5 });
			this._editPicker.timepicker("setTime", value);

			return this._editPicker;
        },

        insertValue: function() {
			var dt = null;
			if(this._insertPicker.val() != null) dt = this._insertPicker.val();
            return dt;
        },

        editValue: function() {
			var dt = null;
			if(this._editPicker.val() != null) dt = this._editPicker.val();
            return dt;
        }
    });


	jsGrid.fields.time = MyTimeField;

