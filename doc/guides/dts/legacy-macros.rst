.. _dt-legacy-macros:

Legacy devicetree macros
########################

.. warning::

   As of Zephyr v2.3, you can still use these macros if you set
   ``CONFIG_LEGACY_DEVICETREE_MACROS=y`` in your application's :ref:`kconfig`.
   Legacy macro support will be maintained for at least two releases, including
   v2.3 itself.

   See :ref:`dt-from-c` for a usage guide for the new API, and
   :ref:`dt-migrate-legacy` for a migration guide for existing code.

This page describes legacy C preprocessor macros which Zephyr's :ref:`build
system <build_overview>` generates from a devicetree. It assumes you're
familiar with the concepts in :ref:`devicetree-intro` and :ref:`dt-bindings`.

These macros have somewhat inconsistent names, and their use in new code is
discouraged. See :ref:`dt-from-c` for the recommended API.

These macros are generated by the :ref:`devicetree scripts <dt-scripts>`,
start with ``DT_``, and use all-uppercase.

.. _dt-legacy-node-identifiers:

Legacy node identifiers
***********************

Macros generated from individual devicetree nodes or their properties start
with ``DT_<node>``, where ``<node>`` is a C identifier for the devicetree node.
This section describes the different ``<node>`` values in the legacy macros.

.. _dt-legacy-node-main-ex:

We'll use the following DTS fragment from the :ref:`FRDM-K64F <frdm_k64f>`
board's devicetree as the main example throughout this section.

.. code-block:: DTS

   / {

        aliases {
                i2c-0 = &i2c0;
        };

        soc {
                i2c0: i2c@40066000 {
                        compatible = "nxp,kinetis-i2c";
                        reg = <0x40066000 0x1000>;
                        status = "okay";
                        /* ... */

                        fxos8700@1d {
                                compatible = "nxp,fxos8700";
                                status = "okay";
                                /* ... */
                        };
                };
        };
   };

The binding for the "nxp,fxos8700" :ref:`compatible property
<dt-important-props>` contains this line:

.. code-block:: yaml

   on-bus: i2c

The generated macros for this example can be found in a build directory for the
:ref:`FXOS8700 sample application <fxos8700>` built for the ``frdm_k64f``
board, in the file
:file:`build/zephyr/include/generated/devicetree_legacy_unfixed.h`.

Here is part of :file:`devicetree_legacy_unfixed.h` showing some of the macros
for the node labeled ``i2c0``. Notice the comment with the node's path in the
devicetree and its dependency relationships with other nodes.

.. code-block:: c

   /*
    * Devicetree node:
    *   /soc/i2c@40066000
    *
    * Binding (compatible = nxp,kinetis-i2c):
    *   $ZEPHYR_BASE/dts/bindings/i2c/nxp,kinetis-i2c.yaml
    *
    * Dependency Ordinal: 66
    *
    * Requires:
    *   6   /soc
    *   ...
    *
    * Supports:
    *   67  /soc/i2c@40066000/fxos8700@1d
    *
    * Description:
    *   Kinetis I2C node
    */
   #define DT_NXP_KINETIS_I2C_40066000_BASE_ADDRESS    0x40066000
   #define DT_NXP_KINETIS_I2C_40066000_SIZE            4096
   #define DT_ALIAS_I2C_0_BASE_ADDRESS                 DT_NXP_KINETIS_I2C_40066000_BASE_ADDRESS
   #define DT_ALIAS_I2C_0_SIZE                         DT_NXP_KINETIS_I2C_40066000_SIZE
   #define DT_INST_0_NXP_KINETIS_I2C_BASE_ADDRESS      DT_NXP_KINETIS_I2C_40066000_BASE_ADDRESS
   #define DT_INST_0_NXP_KINETIS_I2C_SIZE              DT_NXP_KINETIS_I2C_40066000_SIZE

Most macros are generated for individual nodes or their properties. Some macros
are generated for "global" information about the entire devicetree.

In this example, the node identifiers for ``i2c@40066000`` are:

- ``NXP_KINETIS_I2C_40066000``
- ``ALIAS_I2C_0``
- ``INST_0_NXP_KINETIS_I2C``

In general, the following ``DT_<node>`` macro prefixes are created for each
node.

``DT_(<bus>_)<compatible>_<unit-address>``
    The node's compatible property converted to a C identifier, followed by its
    :ref:`unit address <dt-unit-address>`. If the node has multiple compatible
    strings, the one for its :ref:`matching binding <dt-binding-compat>` is
    used.

    If the node appears on a bus (and therefore has ``on-bus:`` in its binding,
    like ``fxos8700@1d`` does), then the compatible string and unit address of
    the bus node is put before the compatible string for the node itself. If
    the node does not appear on a bus (no ``on-bus:`` in the binding, like
    ``i2c@40066000``) then there will be no ``<bus>_`` portion in the node
    identifier.

    The ``i2c@40066000`` node identifier is ``NXP_KINETIS_I2C_40066000``:

    - there is no ``<bus>_`` portion
    - ``<compatible>`` is ``NXP_KINETIS_I2C``, which is its
      compatible ``"nxp,kinetis-i2c"`` converted to a C identifier
      by uppercasing and replacing non-alphanumeric characters with underscores
    - ``<unit-address>`` is ``40066000``

    The ``fxos8700@1d`` node identifier is
    ``NXP_KINETIS_I2C_40066000_NXP_FXOS8700_1D``:

    - ``<bus>`` is ``NXP_KINETIS_I2C_40066000``
    - ``<compatible>`` is ``NXP_FXOS8700``
    - ``<unit-address>`` is ``1D``

    If the node has no unit address, the unit address of the parent node plus
    the node's name converted to a C identifier is used for ``<unit-address>``
    instead. If the parent node has no unit address either, the name of the
    node is used as a fallback.

    For example, take this DTS fragment:

    .. code-block:: DTS

       ethernet@400c0004 {
               compatible = "nxp,kinetis-ethernet";
               reg = <0x400c0004 0x620>;
               status = "okay";
               ptp {
                       compatible = "nxp,kinetis-ptp";
                       status = "okay";
                       interrupts = <0x52 0x0>;
               };
       };

    The ``ptp`` node identifier is ``NXP_KINETIS_PTP_400C0004_PTP``:

    - there is no ``<bus>_`` portion
    - ``<compatible>`` is ``NXP_KINETIS_PTP``
    - ``<unit-address>`` is ``400C0004_PTP``, which combines its parent's unit
      address and the node's name converted to a C identifier

    Here is another example DTS fragment.

    .. code-block:: DTS

       soc {
              temp1 {
                      compatible = "nxp,kinetis-temperature";
                      status = "okay";
              };
       };

    The ``temp1`` node identifier is ``NXP_KINETIS_TEMPERATURE_TEMP1``:

    - there is no ``<bus>_`` portion
    - ``<compatible>`` is ``NXP_KINETIS_TEMPERATURE``
    - ``<unit-address>`` is the fallback value  ``TEMP1``, because neither
      the node nor its parent have a unit address

``DT_INST_<instance-number>_<compatible>``
    An instance number for the node, combined with its compatible
    converted to a C identifier.

    The instance number is a unique index among all enabled
    (``status = "okay"``) nodes that have a particular compatible string,
    starting from zero.

    The ``i2c@40066000`` node identifier in the :ref:`main example
    <dt-legacy-node-main-ex>` is ``INST_0_NXP_KINETIS_I2C``:

    - ``<instance-number>`` is 0 because it was the first node with compatible
      "nxp,kinetis-i2c" that the devicetree scripts happened to discover as they
      walked the tree
    - ``<compatible>`` is ``NXP_KINETIS_I2C``

    As another example, if there are two enabled nodes that have ``compatible =
    "foo,uart"``, then these node identifiers get generated:

    .. code-block:: none

       INST_0_FOO_UART
       INST_1_FOO_UART

    .. warning::

       Instance numbers are simple indexes among enabled nodes with the same
       compatible. They **in no way reflect** any numbering scheme that might
       exist in SoC documentation, node labels or unit addresses, or properties
       of the /aliases node.

       There is no guarantee that the same node will have the same instance
       number between application builds. The only guarantee is that instance
       numbers will start at 0, be contiguous, and be assigned for each enabled
       node with a matching compatible.

``DT_ALIAS_<alias>``
    Generated from the names of any properties in the ``/aliases`` node.
    See :ref:`dt-alias-chosen` for an overview.

    Here is a simple example.

    .. code-block:: DTS

       / {
           aliases {
                   uart-1 = &my_uart;
           };

           my_uart: uart@12345 { /* ... */ };
       };

    The ``uart@12345`` node identifier is ``ALIAS_UART_1``: ``<alias>`` is
    ``UART_1`` by uppercasing ``uart-1`` and replacing non-alphanumeric
    characters with underscores. The alias refers to ``uart@12345`` using its
    :ref:`label <dt-node-labels>` ``my_uart``.

    For such a simple concept, dealing with aliases can be surprisingly tricky
    due to multiple names which have only minor differences.

    For a real-world example, the ``i2c@40066000`` node's alias identifier in
    the :ref:`main example <dt-legacy-node-main-ex>` is ``ALIAS_I2C_0``:
    ``<alias>`` is ``I2C_0`` because the property ``i2c-0 = &i2c0;`` in the
    ``/aliases`` node "points at" ``i2c@40066000`` using its label ``i2c0``.
    The alias name ``i2c-0`` is converted to C identifier ``I2C_0``.

    The differences between ``i2c-0``, ``&i2c0``, ``i2c0``, and
    ``i2c@40006000`` in this example are very subtle and can be quite confusing
    at first. Here is some more clarification:

    - ``i2c-0`` is the *name* of a property in the ``/aliases`` node; this is
      the alias name
    - ``&i2c0`` is that property's *value*, which is the *phandle* of the
      the node with label ``i2c0``
    - ``i2c@40006000`` is the name of the node which happens to have label
      ``i2c0`` in this example

    See the devicetree specification for full details.

    .. note::

       Another ``DT_<compatible>_<alias>`` form is also
       generated for aliases. For the example above, assuming the compatible
       string for the ``&uart1`` node is ``"foo,uart"``, this gives
       ``DT_FOO_UART_UART_1``.

.. _legacy-property-macros:

Macros generated for properties
*******************************

Macros for node property values have the form ``DT_<node>_<property>``, where
``<node>`` is a :ref:`node identifier <dt-legacy-node-identifiers>` and ``<property>``
identifies the property. The macros generated for a property usually depend on
its ``type:`` key in the matching devicetree binding.

The following general purpose rules apply in most cases:

- :ref:`generic-legacy-macros`
- :ref:`phandle-array-legacy-macros`
- :ref:`enum-legacy-macros`

However, some "special" properties get individual treatment:

- :ref:`reg_legacy_macros`
- :ref:`irq_legacy_macros`
- :ref:`clk_legacy_macros`
- :ref:`spi_cs_legacy_macros`

No macros are currently generated for properties with type ``phandle``,
``phandles``, ``path``, or ``compound``.

.. _generic-legacy-macros:

Generic property macros
=======================

This section documents the macros generated for non-"special" properties by
example. These properties are handled based on their devicetree binding
``type:`` keys.

In the generic case, the ``<property>`` portion of a ``DT_<node>_<property>``
macro begins with the property's name converted to a C identifier by
uppercasing it and replacing non-alphanumeric characters with underscores. For
example, a ``baud-rate`` property has a ``<property>`` portion that starts with
``BAUD_RATE``.

The table below gives the values generated for simple types. Note that an index
is added at the end of identifiers generated from properties with ``array`` or
``string-array`` type, and that ``array`` properties generate an additional
compound initializer (``{ ... }``).



+------------------+------------------------+----------------------------------------+
| Type             | Property and value     | Generated macros                       |
+==================+========================+========================================+
| ``int``          | ``foo = <1>``          | ``#define DT_<node>_FOO 1``            |
+------------------+------------------------+----------------------------------------+
| ``array``        | ``foo = <1 2>``        | | ``#define DT_<node>_FOO_0 1``        |
|                  |                        | | ``#define DT_<node>_FOO_1 2``        |
|                  |                        | | ``#define DT_<node>_FOO {1, 2}``     |
+------------------+------------------------+----------------------------------------+
| ``string``       | ``foo = "bar"``        | ``#define DT_<node>_FOO "bar"``        |
+------------------+------------------------+----------------------------------------+
| ``string-array`` | ``foo = "bar", "baz"`` | | ``#define DT_<node>_FOO_0 "bar"``    |
|                  |                        | | ``#define DT_<node>_FOO_1 "baz"``    |
+------------------+------------------------+----------------------------------------+
| ``uint8-array``  | ``foo = [01 02]``      | ``#define DT_<node>_FOO {0x01, 0x02}`` |
+------------------+------------------------+----------------------------------------+

For ``type: boolean``, the generated macro is set to 1 if the property exists
on the node, and to 0 otherwise:

.. code-block:: none

   #define DT_<node>_FOO 0/1

For non-boolean types the property macros are not generated if the binding's
``category`` is ``optional`` and the property is not present in the devicetree
source.

.. _phandle-array-legacy-macros:

Properties with type ``phandle-array``
======================================

The generation for properties with type ``phandle-array`` is the most complex.
To understand it, it is a good idea to first go through the documentation for
``phandle-array`` in :ref:`dt-bindings`.

Take the following devicetree nodes and binding contents as an example:

.. code-block:: DTS
   :caption: Devicetree nodes for PWM controllers

   pwm_ctrl_0: pwm-controller-0 {
        label = "pwm-0";
        #pwm-cells = <2>;
        /* ... */
   };

   pwm_ctrl_1: pwm-controller-1 {
        label = "pwm-1";
        #pwm-cells = <2>;
        /* ... */
   };

.. code-block:: yaml
   :caption: ``pwm-cells`` declaration in binding for ``vendor,pwm-controller``

   pwm-cells:
       - channel
       - period

Assume the property assignment looks like this:

.. code-block:: DTS

   pwm-user@0 {
           status = "okay";
           pwms = <&pwm_ctrl_0 1 10>, <&pwm_ctrl_1 2 20>;
           pwm-names = "first", "second";
           /* ... */
   };

These macros then get generated.

.. code-block:: none

   #define DT_<node>_PWMS_CONTROLLER_0        "pwm-0"
   #define DT_<node>_PWMS_CHANNEL_0           1
   #define DT_<node>_PWMS_PERIOD_0            10

   #define DT_<node>_PWMS_CONTROLLER_1        "pwm-1"
   #define DT_<node>_PWMS_CHANNEL_1           2
   #define DT_<node>_PWMS_PERIOD_1            20

   #define DT_<node>_PWMS_NAMES_0             "first"
   #define DT_<node>_PWMS_NAMES_1             "second"

   #define DT_<node>_FIRST_PWMS_CONTROLLER    DT_<node>_PWMS_CONTROLLER_0
   #define DT_<node>_FIRST_PWMS_CHANNEL       DT_<node>_PWMS_CHANNEL_0
   #define DT_<node>_FIRST_PWMS_PERIOD        DT_<node>_PWMS_PERIOD_0

   #define DT_<node>_SECOND_PWMS_CONTROLLER   DT_<node>_PWMS_CONTROLLER_1
   #define DT_<node>_SECOND_PWMS_CHANNEL      DT_<node>_PWMS_CHANNEL_1
   #define DT_<node>_SECOND_PWMS_PERIOD       DT_<node>_PWMS_PERIOD_1

   /* Initializers */

   #define DT_<node>_PWMS_0                   {"pwm-0", 1, 10}
   #define DT_<node>_PWMS_1                   {"pwm-1", 2, 20}
   #define DT_<node>_PWMS                     {DT_<node>_PWMS_0, DT_<node>_PWMS_1}
   #define DT_<node>_PWMS_COUNT               2

Macros with a ``*_0`` suffix deal with the first entry in ``pwms``
(``<&pwm_ctrl_0 1 10>``). Macros with a ``*_1`` suffix deal with the second
entry (``<&pwm_ctrl_1 2 20>``). The index suffix is only added if there's more
than one entry in the property.

The ``DT_<node>_PWMS_CONTROLLER(_<index>)`` macros are set to the string from
the ``label`` property of the referenced controller. The
``DT_<node>_PWMS_CHANNEL(_<index>)`` and ``DT_<node>_PWMS_PERIOD(_<index>)``
macros are set to the values of the corresponding cells in the ``pwms``
property, with macro names generated from the strings in ``pwm-cells:`` in
the binding for the controller.

The macros in the ``/* Initializers */`` section provide the same information
as ``DT_<node>_PWMS_{CONTROLLER,CHANNEL,PERIOD}(_<index>)``, except as compound
initializers that can be used to initialize C ``struct`` variables.

If a ``pwm-names`` property exists on the same node as ``pwms`` (more
generally, if a ``foo-names`` property is defined next to a ``foo`` property
with type ``phandle-array``), it gives a list of strings that name each entry
in ``pwms``. The names are used to generate extra macro names with the name
instead of an index, like ``DT_<node>_FIRST_PWMS_CONTROLLER`` above.

.. _enum-legacy-macros:

Properties with ``enum:`` in the binding
========================================

Properties declared with an ``enum:`` key in their binding generate a macro
that gives the the zero-based index of the property's value in the ``enum:``
list.

Take this binding declaration as an example:

.. code-block:: yaml

   properties:
       foo:
           type: string
           enum:
               - one
               - two
               - three

The property ``foo = "three"`` then generates this macro:

.. code-block:: none

    #define DT_<node>_FOO_ENUM 2

.. _reg_legacy_macros:

``reg`` property macros
=======================

``reg`` properties generate the macros ``DT_<node>_BASE_ADDRESS(_<index>)`` and
``DT_<node>_SIZE(_<index>)``. ``<index>`` is a numeric index starting from 0,
which is only added if there's more than one register defined in ``reg``.

For example, the ``reg = <0x4004700 0x1060>`` assignment in the example
devicetree above gives these macros:

.. code-block:: none

   #define DT_<node>_BASE_ADDRESS    0x40047000
   #define DT_<node>_SIZE            4192

.. note::

   The length of the address and size portions of ``reg`` is determined from
   the ``#address-cells`` and ``#size-cells`` properties. See the devicetree
   specification for more information.

   In this case, both ``#address-cells`` and ``#size-cells`` are 1, and there's
   just a single register in ``reg``. Four numbers would give two registers.

If a ``reg-names`` property exists on the same node as ``reg``, it gives a list
of strings that names each register in ``reg``. The names are used to generate
extra macros. For example, ``reg-names = "foo"`` together with the example node
generates these macros:

.. code-block:: c

   #define DT_<node>_FOO_BASE_ADDRESS    0x40047000
   #define DT_<node>_FOO_SIZE            4192

.. _irq_legacy_macros:

``interrupts`` property macros
==============================

Take these devicetree nodes as an example:

.. code-block:: DTS

   timer@123 {
        interrupts = <1 5 2 6>;
        interrupt-parent = <&intc>;
        /* ... */
   };

   intc: interrupt-controller { /* ... */ };

Assume that the binding for ``interrupt-controller`` has these lines:

.. code-block:: yaml

   interrupt-cells:
       - irq
       - priority

Then these macros get generated for ``timer@123``:

.. code-block:: c

   #define DT_<node>_IRQ_0                   1
   #define DT_<node>_IRQ_0_PRIORITY          5
   #define DT_<node>_IRQ_1                   2
   #define DT_<node>_IRQ_1_PRIORITY          6

These macros have the the format ``DT_<node>_IRQ_<index>(_<name>)``, where
``<node>`` is the node identifier for ``timer@123``, ``<index>`` is an index
that identifies the particular interrupt, and ``<name>`` is the identifier for
the cell value (a number within ``interrupts = <...>``), taken from the
binding.

Bindings for interrupt controllers are expected to declare a cell named ``irq``
in ``interrupt-cells``, giving the interrupt number. The ``_<name>`` suffix is
skipped for macros generated from ``irq`` cells, which is why there's e.g. a
``DT_<node>_IRQ_0`` macro and no ``DT_<node>_IRQ_0_IRQ`` macro.

If the interrupt controller in turn generates other interrupts, Zephyr uses a
multi-level interrupt encoding for the interrupt numbers at each level. See
:ref:`multi_level_interrupts` for more information.

There is also hard-coded logic for mapping Arm GIC interrupts to linear IRQ
numbers. See the source code for details.

Additional macros that use names instead of indices for interrupts can be
generated by including an ``interrupt-names`` property on the
interrupt-generating node. For example, this node:

.. code-block:: DTS

   timer@456 {
       interrupts = <10 50 20 60>;
       interrupt-parent = <&intc>;
       interrupt-names = "timer-a", "timer-b";
       /* ... */
   };

generates these macros:

.. code-block:: c

   #define DT_<node>_IRQ_TIMER_A             1
   #define DT_<node>_IRQ_TIMER_A_PRIORITY    5
   #define DT_<node>_IRQ_TIMER_B             2
   #define DT_<node>_IRQ_TIMER_B_PRIORITY    6

.. _clk_legacy_macros:

``clocks`` property macros
==========================

``clocks`` work the same as other :ref:`phandle-array-legacy-macros`, except the
generated macros have ``CLOCK`` in them instead of ``CLOCKS``, giving for
example ``DT_<node>_CLOCK_CONTROLLER_0`` instead of
``DT_<node>_CLOCKS_CONTROLLER_0``.

If a ``clocks`` controller node has a ``"fixed-clock"`` compatible, it
must also have a ``clock-frequency`` property giving its frequency in Hertz.
In this case, an additional macro is generated:

.. code-block:: none

   #define DT_<node>_CLOCKS_CLOCK_FREQUENCY <frequency>

.. _spi_cs_legacy_macros:

``cs-gpios`` property macros
============================

.. boards/arm/sensortile_box/sensortile_box.dts has a real-world example

Take these devicetree nodes as an example. where the binding for
``vendor,spi-controller`` is assumed to have ``bus: spi``, and the bindings for
the SPI slaves are assumed to have ``on-bus: spi``:

.. code-block:: DTS

   gpioa: gpio@400ff000 {
        compatible = "vendor,gpio-ctlr";
        reg = <0x400ff000 0x40>;
        label = "GPIOA";
        gpio-controller;
        #gpio-cells = <0x1>;
   };

   spi {
	compatible = "vendor,spi-controller";
	cs-gpios = <&gpioa 1>, <&gpioa 2>;
	spi-slave@0 {
		compatible = "vendor,foo-spi-device";
		reg = <0>;
	};
	spi-slave@1 {
		compatible = "vendor,bar-spi-device";
		reg = <1>;
	};
   };

Here, the unit address of the SPI slaves (0 and 1) is taken as a chip select
number, which is used as an index into ``cs-gpios`` (a ``phandle-array``).
``spi-slave@0`` is matched to ``<&gpioa 1>``, and ``spi-slave@1`` to
``<&gpiob 2>``.

The output for ``spi-slave@0`` and ``spi-slave@1`` is the same as if the
devicetree had looked like this:

.. code-block:: DTS

   gpioa: gpio@400ff000 {
        compatible = "vendor,gpio-ctlr";
        reg = <0x400ff000 0x40>;
        label = "GPIOA";
        gpio-controller;
        #gpio-cells = <1>;
   };

   spi {
	compatible = "vendor,spi-controller";
	spi-slave@0 {
		compatible = "vendor,foo-spi-device";
		reg = <0>;
		cs-gpios = <&gpioa 1>;
	};
	spi-slave@1 {
		compatible = "vendor,bar-spi-device";
		reg = <1>;
		cs-gpios = <&gpioa 2>;
	};
   };

See the ``phandle-array`` section in :ref:`generic-legacy-macros` for more
information.

For example, since the node labeled ``gpioa`` has property
``label = "GPIOA"`` and 1 and 2 are pin numbers, macros like the following
will be generated for ``spi-slave@0``:

.. code-block:: none

   #define DT_<node>_CS_GPIOS_CONTROLLER    "GPIOA"
   #define DT_<node>_CS_GPIOS_PIN           1

.. _other-macros:

Other macros
************

These are generated in addition to macros generated for :ref:`properties
<legacy-property-macros>`.

- :ref:`dt-existence-legacy-macros`
- :ref:`bus-legacy-macros`
- :ref:`flash-legacy-macros`

.. _dt-existence-legacy-macros:

Node existence flags
====================

An "existence flag" is a macro which is defined when the devicetree contains
nodes matching some criterion.

Existence flags are generated for each compatible property that appears on an
enabled node:

.. code-block:: none

   #define DT_COMPAT_<compatible> 1

An existence flag is also written for all enabled nodes with a matching
compatible:

.. code-block:: none

   #define DT_INST_<instance-number>_<compatible>    1

For the ``i2c@40066000`` node in the :ref:`example <dt-legacy-node-main-ex>` above,
assuming the node is the first node with ``compatible = "nxp,kinetis-i2c"``,
the following existence flags would be generated:

.. code-block:: c

   /* At least one node had compatible nxp,kinetis-i2c: */
   #define DT_COMPAT_NXP_KINETIS_I2C    1

   /* Instance 0 of compatible nxp,kinetis-i2c exists: */
   #define DT_INST_0_NXP_KINETIS_I2C    1

If additional nodes had compatible ``nxp,kinetis-i2c``, additional existence
flags would be generated:

.. code-block:: c

   #define DT_INST_1_NXP_KINETIS_I2C    1
   #define DT_INST_2_NXP_KINETIS_I2C    1
   /* ... and so on, one for each node with this compatible. */

.. _bus-legacy-macros:

Bus-related macros
==================

These macros get generated for nodes that appear on buses (have ``on-bus:`` in
their binding):

.. code-block:: none

   #define DT_<node>_BUS_NAME                "<bus-label>"
   #define DT_<compatible>_BUS_<bus-name>    1

``<bus-label>`` is taken from the ``label`` property on the bus node, which
must exist. ``<bus-name>`` is the identifier for the bus as given in
``on-bus:`` in the binding.

.. _flash-legacy-macros:

Macros generated from flash partitions
======================================

.. note::

   This section only covers flash partitions. See :ref:`dt-alias-chosen` for
   some other flash-related macros that get generated from devicetree, via
   ``/chosen``.

If a node has a name that looks like ``partition@<unit-address>``, it is
assumed to represent a flash partition.

Assume the devicetree has this:

.. code-block:: DTS

   flash@0 {
        /* ... */
        label = "foo-flash";

        partitions {
                /* ... */
                #address-cells = <1>;
                #size-cells = <1>;

                boot_partition: partition@0 {
                        label = "mcuboot";
                        reg = <0x00000000 0x00010000>;
                        read-only;
                };
                slot0_partition: partition@10000 {
                        label = "image-0";
                        reg = <0x00010000 0x00020000
                               0x00040000 0x00010000>;
                };
                /* ... */
   };

These macros then get generated:

.. code-block:: c

   #define DT_FLASH_AREA_MCUBOOT_ID           0
   #define DT_FLASH_AREA_MCUBOOT_READ_ONLY    1
   #define DT_FLASH_AREA_MCUBOOT_OFFSET_0     0x0
   #define DT_FLASH_AREA_MCUBOOT_SIZE_0       0x10000
   #define DT_FLASH_AREA_MCUBOOT_OFFSET       DT_FLASH_AREA_MCUBOOT_OFFSET_0
   #define DT_FLASH_AREA_MCUBOOT_SIZE         DT_FLASH_AREA_MCUBOOT_SIZE_0
   #define DT_FLASH_AREA_MCUBOOT_DEV          "foo-flash"

   #define DT_FLASH_AREA_IMAGE_0_ID           0
   #define DT_FLASH_AREA_IMAGE_0_READ_ONLY    1
   #define DT_FLASH_AREA_IMAGE_0_OFFSET_0     0x10000
   #define DT_FLASH_AREA_IMAGE_0_SIZE_0       0x20000
   #define DT_FLASH_AREA_IMAGE_0_OFFSET_1     0x40000
   #define DT_FLASH_AREA_IMAGE_0_SIZE_1       0x10000
   #define DT_FLASH_AREA_IMAGE_0_OFFSET       DT_FLASH_AREA_IMAGE_0_OFFSET_0
   #define DT_FLASH_AREA_IMAGE_0_SIZE         DT_FLASH_AREA_IMAGE_0_SIZE_0
   #define DT_FLASH_AREA_IMAGE_0_DEV          "foo-flash"

   /* Same macros, just with index instead of label */
   #define DT_FLASH_AREA_0_ID           0
   #define DT_FLASH_AREA_0_READ_ONLY    1
   ...

The ``*_ID`` macro gives the zero-based index for the partition.

The ``*_OFFSET_<index>`` and ``*_SIZE_<index>`` macros give the offset and size
for each partition, derived from ``reg``. The ``*_OFFSET`` and ``*_SIZE``
macros, with no index, are aliases that point to the first sector (with index
0).

.. _dt-alias-chosen:

``aliases`` and ``chosen`` nodes
================================

Using an alias with a common name for a particular node makes it easier for you
to write board-independent source code. Devicetree ``aliases`` nodes  are used
for this purpose, by mapping certain generic, commonly used names to specific
hardware resources:

.. code-block:: yaml

   aliases {
      led0 = &led0;
      sw0 = &button0;
      sw1 = &button1;
      uart-0 = &uart0;
      uart-1 = &uart1;
   };

Certain software subsystems require a specific hardware resource to bind to in
order to function properly. Some of those subsystems are used with many
different boards, which makes using the devicetree ``chosen`` nodes very
convenient. By doing so, the software subsystem can rely on having the specific
hardware peripheral assigned to it. In the following example we bind the shell
to ``uart1`` in this board:

.. code-block:: yaml

   chosen {
      zephyr,shell-uart = &uart1;
   };

The table below lists Zephyr-specific ``chosen`` properties. The macro
identifiers that start with ``CONFIG_*`` are generated from Kconfig symbols
that reference devicetree data via the :ref:`Kconfig preprocessor
<kconfig-functions>`.

.. note::

   Since the particular devicetree isn't known while generating Kconfig
   documentation, the Kconfig symbol reference pages linked below do not
   include information derived from devicetree. Instead, you might see e.g. an
   empty default:

   .. code-block:: none

      default "" if HAS_DTS

   To see how the preprocessor is used for a symbol, look it up directly in the
   :file:`Kconfig` file where it is defined instead. The reference page for the
   symbol gives the definition location.

.. list-table::
   :header-rows: 1

   * - ``chosen`` node name
     - Generated macros

   * - ``zephyr,flash``
     - ``DT_FLASH_BASE_ADDRESS``/``DT_FLASH_SIZE``/``DT_FLASH_ERASE_BLOCK_SIZE``/``DT_FLASH_WRITE_BLOCK_SIZE``
   * - ``zephyr,code-partition``
     - ``DT_CODE_PARTITION_OFFSET``/``DT_CODE_PARTITION_SIZE``
   * - ``zephyr,sram``
     - :option:`CONFIG_SRAM_BASE_ADDRESS`/:option:`CONFIG_SRAM_SIZE`
   * - ``zephyr,ccm``
     - ``DT_CCM_BASE_ADDRESS``/``DT_CCM_SIZE``
   * - ``zephyr,dtcm``
     - ``DT_DTCM_BASE_ADDRESS``/``DT_DTCM_SIZE``
   * - ``zephyr,ipc_shm``
     - ``DT_IPC_SHM_BASE_ADDRESS``/``DT_IPC_SHM_SIZE``
   * - ``zephyr,console``
     - :option:`CONFIG_UART_CONSOLE_ON_DEV_NAME`
   * - ``zephyr,shell-uart``
     - :option:`CONFIG_UART_SHELL_ON_DEV_NAME`
   * - ``zephyr,bt-uart``
     - :option:`CONFIG_BT_UART_ON_DEV_NAME`
   * - ``zephyr,uart-pipe``
     - :option:`CONFIG_UART_PIPE_ON_DEV_NAME`
   * - ``zephyr,bt-mon-uart``
     - :option:`CONFIG_BT_MONITOR_ON_DEV_NAME`
   * - ``zephyr,bt-c2h-uart``
     - :option:`CONFIG_BT_CTLR_TO_HOST_UART_DEV_NAME`
   * - ``zephyr,uart-mcumgr``
     - :option:`CONFIG_UART_MCUMGR_ON_DEV_NAME`

.. _legacy_flash_partitions:

Legacy flash partitions
***********************

Devicetree can be used to describe a partition layout for any flash
device in the system.

Two important uses for this mechanism are:

#. To force the Zephyr image to be linked into a specific area on
   Flash.

   This is useful, for example, if the Zephyr image must be linked at
   some offset from the flash device's start, to be loaded by a
   bootloader at runtime.

#. To generate compile-time definitions for the partition layout,
   which can be shared by Zephyr subsystems and applications to
   operate on specific areas in flash.

   This is useful, for example, to create areas for storing file
   systems or other persistent state.  These defines only describe the
   boundaries of each partition. They don't, for example, initialize a
   partition's flash contents with a file system.

Partitions are generally managed using device tree overlays. See
:ref:`set-devicetree-overlays` for examples.

Defining Partitions
===================

The partition layout for a flash device is described inside the
``partitions`` child node of the flash device's node in the device
tree.

You can define partitions for any flash device on the system.

Most Zephyr-supported SoCs with flash support in device tree
will define a label ``flash0``.   This label refers to the primary
on-die flash programmed to run Zephyr. To generate partitions
for this device, add the following snippet to a device tree overlay
file:

.. code-block:: DTS

	&flash0 {
		partitions {
			compatible = "fixed-partitions";
			#address-cells = <1>;
			#size-cells = <1>;

			/* Define your partitions here; see below */
		};
	};

To define partitions for another flash device, modify the above to
either use its label or provide a complete path to the flash device
node in the device tree.

The content of the ``partitions`` node looks like this:

.. code-block:: DTS

	partitions {
		compatible = "fixed-partitions";
		#address-cells = <1>;
		#size-cells = <1>;

		partition1_label: partition@START_OFFSET_1 {
			label = "partition1_name";
			reg = <0xSTART_OFFSET_1 0xSIZE_1>;
		};

		/* ... */

		partitionN_label: partition@START_OFFSET_N {
			label = "partitionN_name";
			reg = <0xSTART_OFFSET_N 0xSIZE_N>;
		};
	};

Where:

- ``partitionX_label`` are device tree labels that can be used
  elsewhere in the device tree to refer to the partition

- ``partitionX_name`` controls how defines generated by the Zephyr
  build system for this partition will be named

- ``START_OFFSET_x`` is the start offset in hexadecimal notation of
  the partition from the beginning of the flash device

- ``SIZE_x`` is the hexadecimal size, in bytes, of the flash partition

The partitions do not have to cover the entire flash device. The
device tree compiler currently does not check if partitions overlap;
you must ensure they do not when defining them.

Example Primary Flash Partition Layout
======================================

Here is a complete (but hypothetical) example device tree overlay
snippet illustrating these ideas. Notice how the partitions do not
overlap, but also do not cover the entire device.

.. code-block:: DTS

	&flash0 {
		partitions {
			compatible = "fixed-partitions";
			#address-cells = <1>;
			#size-cells = <1>;

			code_dts_label: partition@8000 {
				label = "zephyr-code";
				reg = <0x00008000 0x34000>;
			};

			data_dts_label: partition@70000 {
				label = "application-data";
				reg = <0x00070000 0xD000>;
			};
		};
	};

Linking Zephyr Within a Partition
=================================

To force the linker to output a Zephyr image within a given flash
partition, add this to a device tree overlay:

.. code-block:: DTS

	/ {
		chosen {
			zephyr,code-partition = &slot0_partition;
		};
	};

Then, enable the :option:`CONFIG_USE_DT_CODE_PARTITION` Kconfig option.

Flash Partition Macros
======================

The Zephyr build system generates definitions for each flash device
partition. These definitions are available to any files which
include ``<zephyr.h>``.

Consider this flash partition:

.. code-block:: DTS

	dts_label: partition@START_OFFSET {
		label = "def-name";
		reg = <0xSTART_OFFSET 0xSIZE>;
	};

The build system will generate the following corresponding defines:

.. code-block:: c

   #define DT_FLASH_AREA_DEF_NAME_DEV          "def-name"
   #define DT_FLASH_AREA_DEF_NAME_OFFSET_0     0xSTART_OFFSET
   #define DT_FLASH_AREA_DEF_NAME_SIZE_0       0xSIZE
   #define DT_FLASH_AREA_DEF_NAME_OFFSET       DT_FLASH_AREA_DEF_NAME_OFFSET_0
   #define DT_FLASH_AREA_DEF_NAME_SIZE         DT_FLASH_AREA_DEF_NAME_SIZE_0

As you can see, the ``label`` property is capitalized when forming the
macro names. Other simple conversions to ensure it is a valid C
identifier, such as converting "-" to "_", are also performed. The
offsets and sizes are available as well.

.. _mcuboot_partitions:

MCUboot Partitions
==================

`MCUboot`_ is a secure bootloader for 32-bit microcontrollers.

Some Zephyr boards provide definitions for the flash partitions which
are required to build MCUboot itself, as well as any applications
which must be chain-loaded by MCUboot.

The device tree labels for these partitions are:

**boot_partition**
  This is the partition where the bootloader is expected to be
  placed. MCUboot's build system will attempt to link the MCUboot
  image into this partition.

**slot0_partition**
  MCUboot loads the executable application image from this
  partition. Any application bootable by MCUboot must be linked to run
  from this partition.

**slot1_partition**
  This is the partition which stores firmware upgrade images. Zephyr
  applications which receive firmware updates must ensure the upgrade
  images are placed in this partition (the Zephyr DFU subsystem can be
  used for this purpose). MCUboot checks for upgrade images in this
  partition, and can move them to ``slot0_partition`` for execution.
  The ``slot0_partition`` and ``slot1_partition`` must be the same
  size.

**scratch_partition**
  This partition is used as temporary storage while swapping the
  contents of ``slot0_partition`` and ``slot1_partition``.

.. important::

   Upgrade images are only temporarily stored in ``slot1_partition``.
   They must be linked to execute of out of ``slot0_partition``.

See the  `MCUboot documentation`_ for more details on these partitions.

.. _MCUboot: https://mcuboot.com/

.. _MCUboot documentation:
   https://github.com/runtimeco/mcuboot/blob/master/docs/design.md#image-slots

File System Partitions
======================

**storage_partition**
  This is the area where e.g. LittleFS or NVS or FCB expects its partition.

ABNF grammar
************

This section contains an Augmented Backus-Naur Form grammar for the macros
generated from a devicetree. See `RFC 7405`_ (which extends `RFC 5234`_) for a
syntax specification.

.. literalinclude:: legacy-macros.bnf
   :language: abnf

.. _RFC 7405: https://tools.ietf.org/html/rfc7405
.. _RFC 5234: https://tools.ietf.org/html/rfc5234
